
VARIABLE v_fecha_proceso VARCHAR2(10)

BEGIN
  :v_fecha_proceso := TO_CHAR(SYSDATE, 'YYYY-MM-DD');
END;
/

DECLARE
  v_periodo DATE := TO_DATE(:v_fecha_proceso, 'YYYY-MM-DD');
  v_anno_objetivo NUMBER(4);

  TYPE t_varray_tipos IS VARRAY(2) OF VARCHAR2(50);
  v_tipos t_varray_tipos := t_varray_tipos(
    'Avance en Efectivo',
    'Súper Avance en Efectivo'
  );

  TYPE r_transac IS RECORD (
    numrun            CLIENTE.NUMRUN%TYPE,
    dvrun             CLIENTE.DVRUN%TYPE,
    nro_tarjeta       TRANSACCION_TARJETA_CLIENTE.NRO_TARJETA%TYPE,
    nro_transaccion   TRANSACCION_TARJETA_CLIENTE.NRO_TRANSACCION%TYPE,
    fecha_trans       TRANSACCION_TARJETA_CLIENTE.FECHA_TRANSACCION%TYPE,
    tipo_trans        TIPO_TRANSACCION_TARJETA.NOMBRE_TPTRAN_TARJETA%TYPE,
    monto_base        TRANSACCION_TARJETA_CLIENTE.MONTO_TRANSACCION%TYPE,
    cuotas_tran       TRANSACCION_TARJETA_CLIENTE.TOTAL_CUOTAS_TRANSACCION%TYPE,
    tasa_interes      TIPO_TRANSACCION_TARJETA.TASAINT_TPTRAN_TARJETA%TYPE,
    cuotas_max        TIPO_TRANSACCION_TARJETA.NRO_MAXIMO_CUOTAS_TRAN%TYPE
  );

  v_row r_transac;

  v_total_registros NUMBER := 0;
  v_iteraciones     NUMBER := 0;

  v_monto_total     NUMBER := 0;
  v_porc_aporte     NUMBER := 0;
  v_aporte          NUMBER := 0;

  TYPE t_set_mes IS TABLE OF NUMBER INDEX BY VARCHAR2(6);
  v_meses_set t_set_mes;

  CURSOR c_transacciones IS
    SELECT
      c.numrun,
      c.dvrun,
      ttc.nro_tarjeta,
      ttc.nro_transaccion,
      ttc.fecha_transaccion,
      tpt.nombre_tptran_tarjeta,
      ttc.monto_transaccion,
      ttc.total_cuotas_transaccion,
      tpt.tasaint_tptran_tarjeta,
      tpt.nro_maximo_cuotas_tran
    FROM cliente c
    JOIN tarjeta_cliente tc
      ON tc.numrun = c.numrun
    JOIN transaccion_tarjeta_cliente ttc
      ON ttc.nro_tarjeta = tc.nro_tarjeta
    JOIN tipo_transaccion_tarjeta tpt
      ON tpt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
    WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = v_anno_objetivo
      AND tpt.nombre_tptran_tarjeta IN (v_tipos(1), v_tipos(2))
    ORDER BY ttc.fecha_transaccion, c.numrun;

  CURSOR c_detalle_mes(p_mes_anno VARCHAR2) IS
    SELECT
      tipo_transaccion,
      monto_transaccion,
      aporte_sbif
    FROM detalle_aporte_sbif
    WHERE TO_CHAR(fecha_transaccion,'MMYYYY') = p_mes_anno;

  e_data_inconsistente EXCEPTION;

BEGIN
  IF v_periodo IS NULL THEN
    RAISE e_data_inconsistente;
  END IF;

  v_anno_objetivo := EXTRACT(YEAR FROM v_periodo);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_aporte_sbif';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_aporte_sbif';

  SELECT COUNT(*)
    INTO v_total_registros
  FROM cliente c
  JOIN tarjeta_cliente tc
    ON tc.numrun = c.numrun
  JOIN transaccion_tarjeta_cliente ttc
    ON ttc.nro_tarjeta = tc.nro_tarjeta
  JOIN tipo_transaccion_tarjeta tpt
    ON tpt.cod_tptran_tarjeta = ttc.cod_tptran_tarjeta
  WHERE EXTRACT(YEAR FROM ttc.fecha_transaccion) = v_anno_objetivo
    AND tpt.nombre_tptran_tarjeta IN (v_tipos(1), v_tipos(2));

  OPEN c_transacciones;
  LOOP
    FETCH c_transacciones INTO
      v_row.numrun,
      v_row.dvrun,
      v_row.nro_tarjeta,
      v_row.nro_transaccion,
      v_row.fecha_trans,
      v_row.tipo_trans,
      v_row.monto_base,
      v_row.cuotas_tran,
      v_row.tasa_interes,
      v_row.cuotas_max;

    EXIT WHEN c_transacciones%NOTFOUND;

    v_iteraciones := v_iteraciones + 1;

    IF v_row.cuotas_tran > v_row.cuotas_max THEN
      RAISE e_data_inconsistente;
    END IF;

    v_monto_total := ROUND(v_row.monto_base * (1 + v_row.tasa_interes));

    SELECT porc_aporte_sbif
      INTO v_porc_aporte
    FROM tramo_aporte_sbif
    WHERE v_monto_total BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;

    v_aporte := ROUND(v_monto_total * (v_porc_aporte / 100));

    INSERT INTO detalle_aporte_sbif
      (numrun, dvrun, nro_tarjeta, nro_transaccion, fecha_transaccion,
       tipo_transaccion, monto_transaccion, aporte_sbif)
    VALUES
      (v_row.numrun, v_row.dvrun, v_row.nro_tarjeta, v_row.nro_transaccion,
       v_row.fecha_trans, v_row.tipo_trans, v_monto_total, v_aporte);

    v_meses_set(TO_CHAR(v_row.fecha_trans,'MMYYYY')) := 1;
  END LOOP;
  CLOSE c_transacciones;

  DECLARE
    TYPE t_lista_meses IS TABLE OF VARCHAR2(6);
    v_lista_meses t_lista_meses := t_lista_meses();
    v_mes VARCHAR2(6);

    v_tipo VARCHAR2(40);
    v_monto NUMBER;
    v_ap NUMBER;

    v_monto_sum NUMBER;
    v_ap_sum NUMBER;
  BEGIN
    v_mes := v_meses_set.FIRST;
    WHILE v_mes IS NOT NULL LOOP
      v_lista_meses.EXTEND;
      v_lista_meses(v_lista_meses.COUNT) := v_mes;
      v_mes := v_meses_set.NEXT(v_mes);
    END LOOP;

    FOR i IN 1 .. v_lista_meses.COUNT LOOP
      FOR k IN 1 .. 2 LOOP
        v_monto_sum := 0;
        v_ap_sum := 0;

        OPEN c_detalle_mes(v_lista_meses(i));
        LOOP
          FETCH c_detalle_mes INTO v_tipo, v_monto, v_ap;
          EXIT WHEN c_detalle_mes%NOTFOUND;

          IF v_tipo = v_tipos(k) THEN
            v_monto_sum := v_monto_sum + v_monto;
            v_ap_sum := v_ap_sum + v_ap;
          END IF;
        END LOOP;
        CLOSE c_detalle_mes;

        IF v_monto_sum > 0 THEN
          INSERT INTO resumen_aporte_sbif
            (mes_anno, tipo_transaccion,
             monto_total_transacciones, aporte_total_abif)
          VALUES
            (v_lista_meses(i), v_tipos(k),
             ROUND(v_monto_sum), ROUND(v_ap_sum));
        END IF;
      END LOOP;
    END LOOP;
  END;

  IF v_iteraciones = v_total_registros THEN
    COMMIT;
  ELSE
    ROLLBACK;
  END IF;

EXCEPTION
  WHEN e_data_inconsistente THEN
    -- Excepción incompletitud/inconsistencia
    ROLLBACK;

  WHEN NO_DATA_FOUND THEN
    -- Excepción Oracle (estándar)
    ROLLBACK;

  WHEN OTHERS THEN
    -- Excepción Oracle (genérica)
    ROLLBACK;
END;
/


-- SELECT * FROM DETALLE_APORTE_SBIF;
-- SELECT * FROM RESUMEN_APORTE_SBIF;
