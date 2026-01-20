VARIABLE v_fecha_proceso VARCHAR2(10)

BEGIN
 :v_fecha_proceso := TO_CHAR(SYSDATE, 'YYYY-MM-DD');
END;
/

-- truncate para volver a correr el bloque
TRUNCATE TABLE usuario_clave;

DECLARE
  /* Variables %TYPE */
  v_id_emp         empleado.id_emp%TYPE;
  v_numrun_emp     empleado.numrun_emp%TYPE;
  v_dvrun_emp      empleado.dvrun_emp%TYPE;
  v_appaterno      empleado.appaterno_emp%TYPE;
  v_apmaterno      empleado.apmaterno_emp%TYPE;
  v_pnombre        empleado.pnombre_emp%TYPE;
  v_snombre        empleado.snombre_emp%TYPE;
  v_fecha_nac      empleado.fecha_nac%TYPE;
  v_fecha_contrato empleado.fecha_contrato%TYPE;
  v_sueldo_base    empleado.sueldo_base%TYPE;
  v_estado_civil   estado_civil.nombre_estado_civil%TYPE;

  v_nombre_empleado usuario_clave.nombre_empleado%TYPE;
  v_nombre_usuario  usuario_clave.nombre_usuario%TYPE;
  v_clave_usuario   usuario_clave.clave_usuario%TYPE;

  /* Variables auxiliares */
  v_anios_trabajados NUMBER(3);
  v_ultimo_dig_sueldo NUMBER(1);
  v_run_txt          VARCHAR2(20);
  v_dig3_run         VARCHAR2(1);
  v_anno_nac_mas2    NUMBER(4);
  v_ult3_sueldo_menos1 NUMBER(4);
  v_ult3_sueldo_txt  VARCHAR2(3);
  v_letras_apellido  VARCHAR2(2);
  v_mmYYYY           VARCHAR2(6);

  /* Fecha de proceso como DATE usando bind */
  v_fecha_proceso_dt DATE;

  /* Control */
  v_iter_count     NUMBER := 0;
  v_total_esperado NUMBER := 0;

  e_proceso_incompleto EXCEPTION;
BEGIN
  -- convertir bind a DATE dentro del bloque
  v_fecha_proceso_dt := TO_DATE(:v_fecha_proceso, 'YYYY-MM-DD');

  v_total_esperado := TRUNC((320 - 100) / 10) + 1;

  DBMS_OUTPUT.PUT_LINE('Inicio del proceso de generacion de usuarios');
  DBMS_OUTPUT.PUT_LINE('Fecha de proceso: ' || TO_CHAR(v_fecha_proceso_dt, 'DD/MM/YYYY'));

  v_id_emp := 100;
  WHILE v_id_emp <= 320 LOOP

    DBMS_OUTPUT.PUT_LINE('Procesando empleado ID ' || v_id_emp);

    SELECT
      e.numrun_emp,
      e.dvrun_emp,
      e.appaterno_emp,
      e.apmaterno_emp,
      e.pnombre_emp,
      e.snombre_emp,
      e.fecha_nac,
      e.fecha_contrato,
      e.sueldo_base,
      ec.nombre_estado_civil
    INTO
      v_numrun_emp,
      v_dvrun_emp,
      v_appaterno,
      v_apmaterno,
      v_pnombre,
      v_snombre,
      v_fecha_nac,
      v_fecha_contrato,
      v_sueldo_base,
      v_estado_civil
    FROM empleado e
    JOIN estado_civil ec
      ON ec.id_estado_civil = e.id_estado_civil
    WHERE e.id_emp = v_id_emp;

    v_nombre_empleado := RTRIM(
      v_pnombre || ' ' ||
      NVL(v_snombre, '') || ' ' ||
      v_appaterno || ' ' ||
      v_apmaterno
    );
    
    v_anios_trabajados := EXTRACT(YEAR FROM v_fecha_proceso_dt) - EXTRACT(YEAR FROM v_fecha_contrato);

    v_ultimo_dig_sueldo := MOD(v_sueldo_base, 10);

    v_nombre_usuario :=
      LOWER(SUBSTR(v_estado_civil, 1, 1)) ||
      UPPER(SUBSTR(v_pnombre, 1, 3)) ||
      TO_CHAR(LENGTH(v_pnombre)) ||
      '*' ||
      TO_CHAR(v_ultimo_dig_sueldo) ||
      v_dvrun_emp ||
      TO_CHAR(v_anios_trabajados) ||
      CASE WHEN v_anios_trabajados < 10 THEN 'X' ELSE '' END;

    v_run_txt := TO_CHAR(v_numrun_emp);
    v_dig3_run := SUBSTR(v_run_txt, 3, 1);

    v_anno_nac_mas2 := EXTRACT(YEAR FROM v_fecha_nac) + 2;

    v_ult3_sueldo_menos1 := MOD(v_sueldo_base, 1000) - 1;
    IF v_ult3_sueldo_menos1 < 0 THEN
      v_ult3_sueldo_menos1 := 0;
    END IF;
    v_ult3_sueldo_txt := LPAD(TO_CHAR(v_ult3_sueldo_menos1), 3, '0');

    IF v_estado_civil IN ('CASADO', 'ACUERDO DE UNION CIVIL') THEN
      v_letras_apellido := LOWER(SUBSTR(v_appaterno, 1, 2));
    ELSIF v_estado_civil IN ('DIVORCIADO', 'SOLTERO') THEN
      v_letras_apellido := LOWER(SUBSTR(v_appaterno, 1, 1) || SUBSTR(v_appaterno, -1, 1));
    ELSIF v_estado_civil = 'VIUDO' THEN
      v_letras_apellido := LOWER(SUBSTR(v_appaterno, -3, 1) || SUBSTR(v_appaterno, -2, 1));
    ELSIF v_estado_civil = 'SEPARADO' THEN
      v_letras_apellido := LOWER(SUBSTR(v_appaterno, -2, 2));
    ELSE
      v_letras_apellido := LOWER(SUBSTR(v_appaterno, 1, 2));
    END IF;

    v_mmYYYY := TO_CHAR(v_fecha_proceso_dt, 'MMYYYY');

    v_clave_usuario :=
      v_dig3_run ||
      TO_CHAR(v_anno_nac_mas2) ||
      v_ult3_sueldo_txt ||
      v_letras_apellido ||
      TO_CHAR(v_id_emp) ||
      v_mmYYYY;

    INSERT INTO usuario_clave
      (id_emp, numrun_emp, dvrun_emp, nombre_empleado, nombre_usuario, clave_usuario)
    VALUES
      (v_id_emp, v_numrun_emp, v_dvrun_emp, v_nombre_empleado, v_nombre_usuario, v_clave_usuario);

    v_iter_count := v_iter_count + 1;
    v_id_emp := v_id_emp + 10;
  END LOOP;

  IF v_iter_count = v_total_esperado THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso finalizado correctamente');
    DBMS_OUTPUT.PUT_LINE('Se registraron ' || v_iter_count || ' filas en la tabla usuario_clave');
  ELSE
    RAISE e_proceso_incompleto;
  END IF;

EXCEPTION
  WHEN e_proceso_incompleto THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Proceso incompleto');
    DBMS_OUTPUT.PUT_LINE('Esperado=' || v_total_esperado || ' Procesado=' || v_iter_count);
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Empleado no encontrado para id_emp=' || v_id_emp);
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error en la ejecucion: ' || SQLERRM);
END;
/

