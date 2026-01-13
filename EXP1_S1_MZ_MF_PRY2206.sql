
PASO 1 (ADMIN): Creacion de usuario PRY2206_P1 ===

BEGIN
  EXECUTE IMMEDIATE 'DROP USER PRY2206_P1 CASCADE';
EXCEPTION
  WHEN OTHERS THEN
    -- ORA-01918: user 'PRY2206_P1' does not exist
    IF SQLCODE != -1918 THEN
      RAISE;
    END IF;
END;
/

CREATE USER PRY2206_P1 IDENTIFIED BY "PRY2206.practica_1"
  DEFAULT TABLESPACE "DATA"
  TEMPORARY TABLESPACE "TEMP";

ALTER USER PRY2206_P1 QUOTA UNLIMITED ON DATA;

GRANT CREATE SESSION TO PRY2206_P1;
GRANT "RESOURCE" TO PRY2206_P1;
ALTER USER PRY2206_P1 DEFAULT ROLE "RESOURCE";


-- USUARIO PRY2206 después del poblado de tablas 
-- CASO 1: Procedimiento para los 5 clientes específicos, cada uno con su bloque PL/SQL

-- Karen: 21242003-4
DECLARE
  -- Parámetros 
  v_run          VARCHAR2(15) := '21242003-4';
  v_peso_normal  NUMBER       := 1200;
  v_extra_tramo1 NUMBER       := 100;
  v_extra_tramo2 NUMBER       := 300;
  v_extra_tramo3 NUMBER       := 550;
  v_limite1      NUMBER       := 1000000;
  v_limite2      NUMBER       := 3000000;

  -- Variables de trabajo
  v_nro_cliente      CLIENTE.nro_cliente%TYPE;
  v_run_cliente      VARCHAR2(15);
  v_nombre_cliente   VARCHAR2(50);
  v_tipo_cliente     VARCHAR2(30);

  v_monto_total_sol  NUMBER(10);
  v_factor_100k      NUMBER(10);
  v_extra_por_100k   NUMBER(10);
  v_pesos_total      NUMBER(10);

  v_anio_anterior    NUMBER(4);

BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Buscar cliente por RUT
  SELECT c.nro_cliente,
         c.numrun || '-' || c.dvrun AS run_cliente,
         REGEXP_REPLACE(TRIM(c.pnombre || ' ' || NVL(c.snombre,'') || ' ' || c.appaterno || ' ' || NVL(c.apmaterno,'')),
                        '\s+', ' ') AS nombre_cliente,
         tc.nombre_tipo_cliente
    INTO v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente
    FROM cliente c
    JOIN tipo_cliente tc
      ON tc.cod_tipo_cliente = c.cod_tipo_cliente
   WHERE (c.numrun || '-' || c.dvrun) = v_run;


  -- 3) Sumatoria montos solicitados año anterior
  SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_sol
    FROM credito_cliente cc
   WHERE cc.nro_cliente = v_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  v_factor_100k := TRUNC(v_monto_total_sol / 100000);

   -- 4) Extra por cada $100.000:
  --    - Dependientes: extra = 0
  --    - Independientes: extra según tramo
  IF UPPER(v_tipo_cliente) LIKE '%INDEPEND%' THEN
    IF v_monto_total_sol < v_limite1 THEN
      v_extra_por_100k := v_extra_tramo1;
    ELSIF v_monto_total_sol <= v_limite2 THEN
      v_extra_por_100k := v_extra_tramo2;
    ELSE
      v_extra_por_100k := v_extra_tramo3;
    END IF;
  ELSE
    v_extra_por_100k := 0;
  END IF;

  -- 5) Pesos total
  v_pesos_total := v_factor_100k * (v_peso_normal + v_extra_por_100k);

  -- 6) Re-ejecución: borrar registro previo
  DELETE FROM cliente_todosuma
   WHERE nro_cliente = v_nro_cliente;

  -- 7) Insert
  INSERT INTO cliente_todosuma
    (nro_cliente, run_cliente, nombre_cliente, tipo_cliente, monto_solic_creditos, monto_pesos_todosuma)
  VALUES
    (v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_total_sol, v_pesos_total);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('OK: '||v_nombre_cliente||
                       ' | MontoSolic='||v_monto_total_sol||
                       ' | Pesos='||v_pesos_total||
                       ' | AñoAnterior='||v_anio_anterior);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe cliente con RUN='||v_run);
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/


-- Silvana: 22176845-2
DECLARE
  -- Parámetros 
  v_run          VARCHAR2(15) := '22176845-2';
  v_peso_normal  NUMBER       := 1200;
  v_extra_tramo1 NUMBER       := 100;
  v_extra_tramo2 NUMBER       := 300;
  v_extra_tramo3 NUMBER       := 550;
  v_limite1      NUMBER       := 1000000;
  v_limite2      NUMBER       := 3000000;

  -- Variables de trabajo
  v_nro_cliente      CLIENTE.nro_cliente%TYPE;
  v_run_cliente      VARCHAR2(15);
  v_nombre_cliente   VARCHAR2(50);
  v_tipo_cliente     VARCHAR2(30);

  v_monto_total_sol  NUMBER(10);
  v_factor_100k      NUMBER(10);
  v_extra_por_100k   NUMBER(10);
  v_pesos_total      NUMBER(10);

  v_anio_anterior    NUMBER(4);

BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Buscar cliente por RUT
  SELECT c.nro_cliente,
         c.numrun || '-' || c.dvrun AS run_cliente,
         REGEXP_REPLACE(TRIM(c.pnombre || ' ' || NVL(c.snombre,'') || ' ' || c.appaterno || ' ' || NVL(c.apmaterno,'')),
                        '\s+', ' ') AS nombre_cliente,
         tc.nombre_tipo_cliente
    INTO v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente
    FROM cliente c
    JOIN tipo_cliente tc
      ON tc.cod_tipo_cliente = c.cod_tipo_cliente
   WHERE (c.numrun || '-' || c.dvrun) = v_run;


  -- 3) Sumatoria montos solicitados año anterior
  SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_sol
    FROM credito_cliente cc
   WHERE cc.nro_cliente = v_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  v_factor_100k := TRUNC(v_monto_total_sol / 100000);

   -- 4) Extra por cada $100.000:
  --    - Dependientes: extra = 0
  --    - Independientes: extra según tramo
  IF UPPER(v_tipo_cliente) LIKE '%INDEPEND%' THEN
    IF v_monto_total_sol < v_limite1 THEN
      v_extra_por_100k := v_extra_tramo1;
    ELSIF v_monto_total_sol <= v_limite2 THEN
      v_extra_por_100k := v_extra_tramo2;
    ELSE
      v_extra_por_100k := v_extra_tramo3;
    END IF;
  ELSE
    v_extra_por_100k := 0;
  END IF;

  -- 5) Pesos total
  v_pesos_total := v_factor_100k * (v_peso_normal + v_extra_por_100k);

  -- 6) Re-ejecución: borrar registro previo
  DELETE FROM cliente_todosuma
   WHERE nro_cliente = v_nro_cliente;

  -- 7) Insert
  INSERT INTO cliente_todosuma
    (nro_cliente, run_cliente, nombre_cliente, tipo_cliente, monto_solic_creditos, monto_pesos_todosuma)
  VALUES
    (v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_total_sol, v_pesos_total);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('OK: '||v_nombre_cliente||
                       ' | MontoSolic='||v_monto_total_sol||
                       ' | Pesos='||v_pesos_total||
                       ' | AñoAnterior='||v_anio_anterior);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe cliente con RUN='||v_run);
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/
-- Denisse: 18858542-6

DECLARE
  -- Parámetros 
  v_run          VARCHAR2(15) := '18858542-6';
  v_peso_normal  NUMBER       := 1200;
  v_extra_tramo1 NUMBER       := 100;
  v_extra_tramo2 NUMBER       := 300;
  v_extra_tramo3 NUMBER       := 550;
  v_limite1      NUMBER       := 1000000;
  v_limite2      NUMBER       := 3000000;

  -- Variables de trabajo
  v_nro_cliente      CLIENTE.nro_cliente%TYPE;
  v_run_cliente      VARCHAR2(15);
  v_nombre_cliente   VARCHAR2(50);
  v_tipo_cliente     VARCHAR2(30);

  v_monto_total_sol  NUMBER(10);
  v_factor_100k      NUMBER(10);
  v_extra_por_100k   NUMBER(10);
  v_pesos_total      NUMBER(10);

  v_anio_anterior    NUMBER(4);

BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Buscar cliente por RUT
  SELECT c.nro_cliente,
         c.numrun || '-' || c.dvrun AS run_cliente,
         REGEXP_REPLACE(TRIM(c.pnombre || ' ' || NVL(c.snombre,'') || ' ' || c.appaterno || ' ' || NVL(c.apmaterno,'')),
                        '\s+', ' ') AS nombre_cliente,
         tc.nombre_tipo_cliente
    INTO v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente
    FROM cliente c
    JOIN tipo_cliente tc
      ON tc.cod_tipo_cliente = c.cod_tipo_cliente
   WHERE (c.numrun || '-' || c.dvrun) = v_run;


  -- 3) Sumatoria montos solicitados año anterior
  SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_sol
    FROM credito_cliente cc
   WHERE cc.nro_cliente = v_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  v_factor_100k := TRUNC(v_monto_total_sol / 100000);

   -- 4) Extra por cada $100.000:
  --    - Dependientes: extra = 0
  --    - Independientes: extra según tramo
  IF UPPER(v_tipo_cliente) LIKE '%INDEPEND%' THEN
    IF v_monto_total_sol < v_limite1 THEN
      v_extra_por_100k := v_extra_tramo1;
    ELSIF v_monto_total_sol <= v_limite2 THEN
      v_extra_por_100k := v_extra_tramo2;
    ELSE
      v_extra_por_100k := v_extra_tramo3;
    END IF;
  ELSE
    v_extra_por_100k := 0;
  END IF;

  -- 5) Pesos total
  v_pesos_total := v_factor_100k * (v_peso_normal + v_extra_por_100k);

  -- 6) Re-ejecución: borrar registro previo
  DELETE FROM cliente_todosuma
   WHERE nro_cliente = v_nro_cliente;

  -- 7) Insert
  INSERT INTO cliente_todosuma
    (nro_cliente, run_cliente, nombre_cliente, tipo_cliente, monto_solic_creditos, monto_pesos_todosuma)
  VALUES
    (v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_total_sol, v_pesos_total);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('OK: '||v_nombre_cliente||
                       ' | MontoSolic='||v_monto_total_sol||
                       ' | Pesos='||v_pesos_total||
                       ' | AñoAnterior='||v_anio_anterior);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe cliente con RUN='||v_run);
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/

-- Amanda: 22558061-8
DECLARE
  -- Parámetros 
  v_run          VARCHAR2(15) := '22558061-8';
  v_peso_normal  NUMBER       := 1200;
  v_extra_tramo1 NUMBER       := 100;
  v_extra_tramo2 NUMBER       := 300;
  v_extra_tramo3 NUMBER       := 550;
  v_limite1      NUMBER       := 1000000;
  v_limite2      NUMBER       := 3000000;

  -- Variables de trabajo
  v_nro_cliente      CLIENTE.nro_cliente%TYPE;
  v_run_cliente      VARCHAR2(15);
  v_nombre_cliente   VARCHAR2(50);
  v_tipo_cliente     VARCHAR2(30);

  v_monto_total_sol  NUMBER(10);
  v_factor_100k      NUMBER(10);
  v_extra_por_100k   NUMBER(10);
  v_pesos_total      NUMBER(10);

  v_anio_anterior    NUMBER(4);

BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Buscar cliente por RUT
  SELECT c.nro_cliente,
         c.numrun || '-' || c.dvrun AS run_cliente,
         REGEXP_REPLACE(TRIM(c.pnombre || ' ' || NVL(c.snombre,'') || ' ' || c.appaterno || ' ' || NVL(c.apmaterno,'')),
                        '\s+', ' ') AS nombre_cliente,
         tc.nombre_tipo_cliente
    INTO v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente
    FROM cliente c
    JOIN tipo_cliente tc
      ON tc.cod_tipo_cliente = c.cod_tipo_cliente
   WHERE (c.numrun || '-' || c.dvrun) = v_run;


  -- 3) Sumatoria montos solicitados año anterior
  SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_sol
    FROM credito_cliente cc
   WHERE cc.nro_cliente = v_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  v_factor_100k := TRUNC(v_monto_total_sol / 100000);

   -- 4) Extra por cada $100.000:
  --    - Dependientes: extra = 0
  --    - Independientes: extra según tramo
  IF UPPER(v_tipo_cliente) LIKE '%INDEPEND%' THEN
    IF v_monto_total_sol < v_limite1 THEN
      v_extra_por_100k := v_extra_tramo1;
    ELSIF v_monto_total_sol <= v_limite2 THEN
      v_extra_por_100k := v_extra_tramo2;
    ELSE
      v_extra_por_100k := v_extra_tramo3;
    END IF;
  ELSE
    v_extra_por_100k := 0;
  END IF;

  -- 5) Pesos total
  v_pesos_total := v_factor_100k * (v_peso_normal + v_extra_por_100k);

  -- 6) Re-ejecución: borrar registro previo
  DELETE FROM cliente_todosuma
   WHERE nro_cliente = v_nro_cliente;

  -- 7) Insert
  INSERT INTO cliente_todosuma
    (nro_cliente, run_cliente, nombre_cliente, tipo_cliente, monto_solic_creditos, monto_pesos_todosuma)
  VALUES
    (v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_total_sol, v_pesos_total);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('OK: '||v_nombre_cliente||
                       ' | MontoSolic='||v_monto_total_sol||
                       ' | Pesos='||v_pesos_total||
                       ' | AñoAnterior='||v_anio_anterior);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe cliente con RUN='||v_run);
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/

-- Luis: 21300628-2

DECLARE
  -- Parámetros 
  v_run          VARCHAR2(15) := '21300628-2';
  v_peso_normal  NUMBER       := 1200;
  v_extra_tramo1 NUMBER       := 100;
  v_extra_tramo2 NUMBER       := 300;
  v_extra_tramo3 NUMBER       := 550;
  v_limite1      NUMBER       := 1000000;
  v_limite2      NUMBER       := 3000000;

  -- Variables de trabajo
  v_nro_cliente      CLIENTE.nro_cliente%TYPE;
  v_run_cliente      VARCHAR2(15);
  v_nombre_cliente   VARCHAR2(50);
  v_tipo_cliente     VARCHAR2(30);

  v_monto_total_sol  NUMBER(10);
  v_factor_100k      NUMBER(10);
  v_extra_por_100k   NUMBER(10);
  v_pesos_total      NUMBER(10);

  v_anio_anterior    NUMBER(4);

BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Buscar cliente por RUT
  SELECT c.nro_cliente,
         c.numrun || '-' || c.dvrun AS run_cliente,
         REGEXP_REPLACE(TRIM(c.pnombre || ' ' || NVL(c.snombre,'') || ' ' || c.appaterno || ' ' || NVL(c.apmaterno,'')),
                        '\s+', ' ') AS nombre_cliente,
         tc.nombre_tipo_cliente
    INTO v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente
    FROM cliente c
    JOIN tipo_cliente tc
      ON tc.cod_tipo_cliente = c.cod_tipo_cliente
   WHERE (c.numrun || '-' || c.dvrun) = v_run;


  -- 3) Sumatoria montos solicitados año anterior
  SELECT NVL(SUM(cc.monto_solicitado), 0)
    INTO v_monto_total_sol
    FROM credito_cliente cc
   WHERE cc.nro_cliente = v_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  v_factor_100k := TRUNC(v_monto_total_sol / 100000);

   -- 4) Extra por cada $100.000:
  --    - Dependientes: extra = 0
  --    - Independientes: extra según tramo
  IF UPPER(v_tipo_cliente) LIKE '%INDEPEND%' THEN
    IF v_monto_total_sol < v_limite1 THEN
      v_extra_por_100k := v_extra_tramo1;
    ELSIF v_monto_total_sol <= v_limite2 THEN
      v_extra_por_100k := v_extra_tramo2;
    ELSE
      v_extra_por_100k := v_extra_tramo3;
    END IF;
  ELSE
    v_extra_por_100k := 0;
  END IF;

  -- 5) Pesos total
  v_pesos_total := v_factor_100k * (v_peso_normal + v_extra_por_100k);

  -- 6) Re-ejecución: borrar registro previo
  DELETE FROM cliente_todosuma
   WHERE nro_cliente = v_nro_cliente;

  -- 7) Insert
  INSERT INTO cliente_todosuma
    (nro_cliente, run_cliente, nombre_cliente, tipo_cliente, monto_solic_creditos, monto_pesos_todosuma)
  VALUES
    (v_nro_cliente, v_run_cliente, v_nombre_cliente, v_tipo_cliente, v_monto_total_sol, v_pesos_total);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('OK: '||v_nombre_cliente||
                       ' | MontoSolic='||v_monto_total_sol||
                       ' | Pesos='||v_pesos_total||
                       ' | AñoAnterior='||v_anio_anterior);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe cliente con RUN='||v_run);
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/

SELECT * FROM cliente_todosuma
-- se validan los 5 clientes ya agregados

-- Caso 2


-- 2.1 Sebastian

DECLARE
  -- Parámetros
  b_nro_cliente       NUMBER(5)  := 5;
  b_nro_solic_credito NUMBER(10) := 2001; 
  b_cant_cuotas       NUMBER(2)  := 2;    

  -- Variables
  v_nombre_credito    CREDITO.nombre_credito%TYPE;
  v_anio_anterior     NUMBER(4);

  v_last_nro_cuota    CUOTA_CREDITO_CLIENTE.nro_cuota%TYPE;
  v_last_fecha_venc   CUOTA_CREDITO_CLIENTE.fecha_venc_cuota%TYPE;
  v_last_valor_cuota  CUOTA_CREDITO_CLIENTE.valor_cuota%TYPE;

  v_tasa              NUMBER := 0;        
  v_new_nro_cuota     NUMBER(3);
  v_new_fecha_venc    DATE;
  v_new_valor_cuota   NUMBER(10);

  v_cnt_creditos_aa   NUMBER := 0;        
BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Validar que el crédito pertenezca al cliente y obtener tipo (nombre_credito)
  SELECT cr.nombre_credito
    INTO v_nombre_credito
    FROM credito_cliente cc
    JOIN credito cr
      ON cr.cod_credito = cc.cod_credito
   WHERE cc.nro_solic_credito = b_nro_solic_credito
     AND cc.nro_cliente       = b_nro_cliente;

  -- 2) Obtener última cuota del crédito (nro_cuota mayor)
  SELECT q.nro_cuota, q.fecha_venc_cuota, q.valor_cuota
    INTO v_last_nro_cuota, v_last_fecha_venc, v_last_valor_cuota
    FROM cuota_credito_cliente q
   WHERE q.nro_solic_credito = b_nro_solic_credito
     AND q.nro_cuota = (SELECT MAX(nro_cuota)
                          FROM cuota_credito_cliente
                         WHERE nro_solic_credito = b_nro_solic_credito);

  -- 3) Determinar tasa según tipo de crédito y cantidad de cuotas a postergar
  --    Hipotecario:
  --      - 1 cuota: 0% (sin interés)
  --      - hasta 2 cuotas: 0,5% (0.005)
  --    Consumo:
  --      - 1 cuota: 1% (0.01)
  --    Automotriz:
  --      - 1 cuota: 2% (0.02)
  IF UPPER(v_nombre_credito) LIKE '%HIPOTEC%' THEN
    IF b_cant_cuotas = 1 THEN
      v_tasa := 0;
    ELSIF b_cant_cuotas = 2 THEN
      v_tasa := 0.005;
    ELSE
      RAISE_APPLICATION_ERROR(-20002, 'Crédito hipotecario permite postergar 1 o 2 cuotas. Cantidad='||b_cant_cuotas);
    END IF;

  ELSIF UPPER(v_nombre_credito) LIKE '%CONSUM%' THEN
    IF b_cant_cuotas != 1 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Crédito de consumo permite postergar solo 1 cuota. Cantidad='||b_cant_cuotas);
    END IF;
    v_tasa := 0.01;

  ELSIF UPPER(v_nombre_credito) LIKE '%AUTOM%' THEN
    IF b_cant_cuotas != 1 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Crédito automotriz permite postergar solo 1 cuota. Cantidad='||b_cant_cuotas);
    END IF;
    v_tasa := 0.02;

  ELSE
    RAISE_APPLICATION_ERROR(-20005, 'Tipo de crédito no reconocido para reglas de postergación: '||v_nombre_credito);
  END IF;

  -- 4) Regla adicional: si el cliente solicitó MÁS de 1 crédito en el año anterior,
  --    se condona la deuda de la última cuota del crédito (queda pagada).
  SELECT COUNT(*)
    INTO v_cnt_creditos_aa
    FROM credito_cliente cc
   WHERE cc.nro_cliente = b_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  IF v_cnt_creditos_aa > 1 THEN
    UPDATE cuota_credito_cliente
       SET fecha_pago_cuota = fecha_venc_cuota,
           monto_pagado     = valor_cuota,
           saldo_por_pagar  = 0
     WHERE nro_solic_credito = b_nro_solic_credito
       AND nro_cuota         = v_last_nro_cuota;
  END IF;

  -- 5) Generar e insertar nueva(s) cuota(s)
  --    - nro_cuota correlativo desde la última cuota
  --    - fecha_venc = ADD_MONTHS(fecha_venc_ultima, i)
  --    - valor_cuota = valor_ultima_cuota * (1 + tasa)
  --    - monto_pagado, fecha_pago, saldo_por_pagar, forma_pago = NULL
  FOR i IN 1..b_cant_cuotas LOOP
    v_new_nro_cuota   := v_last_nro_cuota + i;
    v_new_fecha_venc  := ADD_MONTHS(v_last_fecha_venc, i);
    v_new_valor_cuota := ROUND(v_last_valor_cuota * (1 + v_tasa));

    INSERT INTO cuota_credito_cliente
      (nro_solic_credito, nro_cuota, fecha_venc_cuota, valor_cuota,
       fecha_pago_cuota, monto_pagado, saldo_por_pagar, cod_forma_pago)
    VALUES
      (b_nro_solic_credito, v_new_nro_cuota, v_new_fecha_venc, v_new_valor_cuota,
       NULL, NULL, NULL, NULL);
  END LOOP;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Caso 2.1 Sebastián');
  DBMS_OUTPUT.PUT_LINE(' Cliente='||b_nro_cliente||' | Credito='||b_nro_solic_credito||' | Tipo='||v_nombre_credito);
  DBMS_OUTPUT.PUT_LINE(' Postergadas='||b_cant_cuotas||' | Tasa='||TO_CHAR(v_tasa*100,'FM9990D00')||'%');
  DBMS_OUTPUT.PUT_LINE(' UltCuota='||v_last_nro_cuota||' ('||TO_CHAR(v_last_fecha_venc,'YYYY-MM-DD')||') Valor='||v_last_valor_cuota);
  IF v_cnt_creditos_aa > 1 THEN
    DBMS_OUTPUT.PUT_LINE(' Condona última cuota (cliente con '||v_cnt_creditos_aa||' créditos en año anterior '||v_anio_anterior||').');
  ELSE
    DBMS_OUTPUT.PUT_LINE(' No condona última cuota (cliente con '||v_cnt_creditos_aa||' crédito(s) en año anterior '||v_anio_anterior||').');
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe el crédito '||b_nro_solic_credito||' para el cliente '||b_nro_cliente);
    RAISE;
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Ya existen cuotas con ese nro_cuota para este crédito (posible re-ejecución sin limpiar).');
    DBMS_OUTPUT.PUT_LINE('Sugerencia: elimine cuotas generadas (nro_cuota > última original) o pruebe con otro crédito.');
    RAISE;
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/
-- 2.2 Karen

DECLARE
  -- Parámetros
  b_nro_cliente       NUMBER(5)  := 67;
  b_nro_solic_credito NUMBER(10) := 3004; 
  b_cant_cuotas       NUMBER(2)  := 1;    

  -- Variables
  v_nombre_credito    CREDITO.nombre_credito%TYPE;
  v_anio_anterior     NUMBER(4);

  v_last_nro_cuota    CUOTA_CREDITO_CLIENTE.nro_cuota%TYPE;
  v_last_fecha_venc   CUOTA_CREDITO_CLIENTE.fecha_venc_cuota%TYPE;
  v_last_valor_cuota  CUOTA_CREDITO_CLIENTE.valor_cuota%TYPE;

  v_tasa              NUMBER := 0;        
  v_new_nro_cuota     NUMBER(3);
  v_new_fecha_venc    DATE;
  v_new_valor_cuota   NUMBER(10);

  v_cnt_creditos_aa   NUMBER := 0;        
BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Validar que el crédito pertenezca al cliente y obtener tipo (nombre_credito)
  SELECT cr.nombre_credito
    INTO v_nombre_credito
    FROM credito_cliente cc
    JOIN credito cr
      ON cr.cod_credito = cc.cod_credito
   WHERE cc.nro_solic_credito = b_nro_solic_credito
     AND cc.nro_cliente       = b_nro_cliente;

  -- 2) Obtener última cuota del crédito (nro_cuota mayor)
  SELECT q.nro_cuota, q.fecha_venc_cuota, q.valor_cuota
    INTO v_last_nro_cuota, v_last_fecha_venc, v_last_valor_cuota
    FROM cuota_credito_cliente q
   WHERE q.nro_solic_credito = b_nro_solic_credito
     AND q.nro_cuota = (SELECT MAX(nro_cuota)
                          FROM cuota_credito_cliente
                         WHERE nro_solic_credito = b_nro_solic_credito);

  -- 3) Determinar tasa según tipo de crédito y cantidad de cuotas a postergar
  --    Hipotecario:
  --      - 1 cuota: 0% (sin interés)
  --      - hasta 2 cuotas: 0,5% (0.005)
  --    Consumo:
  --      - 1 cuota: 1% (0.01)
  --    Automotriz:
  --      - 1 cuota: 2% (0.02)
  IF UPPER(v_nombre_credito) LIKE '%HIPOTEC%' THEN
    IF b_cant_cuotas = 1 THEN
      v_tasa := 0;
    ELSIF b_cant_cuotas = 2 THEN
      v_tasa := 0.005;
    ELSE
      RAISE_APPLICATION_ERROR(-20002, 'Crédito hipotecario permite postergar 1 o 2 cuotas. Cantidad='||b_cant_cuotas);
    END IF;

  ELSIF UPPER(v_nombre_credito) LIKE '%CONSUM%' THEN
    IF b_cant_cuotas != 1 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Crédito de consumo permite postergar solo 1 cuota. Cantidad='||b_cant_cuotas);
    END IF;
    v_tasa := 0.01;

  ELSIF UPPER(v_nombre_credito) LIKE '%AUTOM%' THEN
    IF b_cant_cuotas != 1 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Crédito automotriz permite postergar solo 1 cuota. Cantidad='||b_cant_cuotas);
    END IF;
    v_tasa := 0.02;

  ELSE
    RAISE_APPLICATION_ERROR(-20005, 'Tipo de crédito no reconocido para reglas de postergación: '||v_nombre_credito);
  END IF;

  -- 4) Regla adicional: si el cliente solicitó MÁS de 1 crédito en el año anterior,
  --    se condona la deuda de la última cuota del crédito (queda pagada).
  SELECT COUNT(*)
    INTO v_cnt_creditos_aa
    FROM credito_cliente cc
   WHERE cc.nro_cliente = b_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  IF v_cnt_creditos_aa > 1 THEN
    UPDATE cuota_credito_cliente
       SET fecha_pago_cuota = fecha_venc_cuota,
           monto_pagado     = valor_cuota,
           saldo_por_pagar  = 0
     WHERE nro_solic_credito = b_nro_solic_credito
       AND nro_cuota         = v_last_nro_cuota;
  END IF;

  -- 5) Generar e insertar nueva(s) cuota(s)
  --    - nro_cuota correlativo desde la última cuota
  --    - fecha_venc = ADD_MONTHS(fecha_venc_ultima, i)
  --    - valor_cuota = valor_ultima_cuota * (1 + tasa)
  --    - monto_pagado, fecha_pago, saldo_por_pagar, forma_pago = NULL
  FOR i IN 1..b_cant_cuotas LOOP
    v_new_nro_cuota   := v_last_nro_cuota + i;
    v_new_fecha_venc  := ADD_MONTHS(v_last_fecha_venc, i);
    v_new_valor_cuota := ROUND(v_last_valor_cuota * (1 + v_tasa));

    INSERT INTO cuota_credito_cliente
      (nro_solic_credito, nro_cuota, fecha_venc_cuota, valor_cuota,
       fecha_pago_cuota, monto_pagado, saldo_por_pagar, cod_forma_pago)
    VALUES
      (b_nro_solic_credito, v_new_nro_cuota, v_new_fecha_venc, v_new_valor_cuota,
       NULL, NULL, NULL, NULL);
  END LOOP;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Caso 2.2 Karen');
  DBMS_OUTPUT.PUT_LINE(' Cliente='||b_nro_cliente||' | Credito='||b_nro_solic_credito||' | Tipo='||v_nombre_credito);
  DBMS_OUTPUT.PUT_LINE(' Postergadas='||b_cant_cuotas||' | Tasa='||TO_CHAR(v_tasa*100,'FM9990D00')||'%');
  DBMS_OUTPUT.PUT_LINE(' UltCuota='||v_last_nro_cuota||' ('||TO_CHAR(v_last_fecha_venc,'YYYY-MM-DD')||') Valor='||v_last_valor_cuota);
  IF v_cnt_creditos_aa > 1 THEN
    DBMS_OUTPUT.PUT_LINE(' Condona última cuota (cliente con '||v_cnt_creditos_aa||' créditos en año anterior '||v_anio_anterior||').');
  ELSE
    DBMS_OUTPUT.PUT_LINE(' No condona última cuota (cliente con '||v_cnt_creditos_aa||' crédito(s) en año anterior '||v_anio_anterior||').');
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe el crédito '||b_nro_solic_credito||' para el cliente '||b_nro_cliente);
    RAISE;
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Ya existen cuotas con ese nro_cuota para este crédito (posible re-ejecución sin limpiar).');
    DBMS_OUTPUT.PUT_LINE('Sugerencia: elimine cuotas generadas (nro_cuota > última original) o pruebe con otro crédito.');
    RAISE;
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/

-- 2.3 Julián

DECLARE
  -- Parámetros
  b_nro_cliente       NUMBER(5)  := 13;
  b_nro_solic_credito NUMBER(10) := 2004; 
  b_cant_cuotas       NUMBER(2)  := 1;    

  -- Variables
  v_nombre_credito    CREDITO.nombre_credito%TYPE;
  v_anio_anterior     NUMBER(4);

  v_last_nro_cuota    CUOTA_CREDITO_CLIENTE.nro_cuota%TYPE;
  v_last_fecha_venc   CUOTA_CREDITO_CLIENTE.fecha_venc_cuota%TYPE;
  v_last_valor_cuota  CUOTA_CREDITO_CLIENTE.valor_cuota%TYPE;

  v_tasa              NUMBER := 0;      
  v_new_nro_cuota     NUMBER(3);
  v_new_fecha_venc    DATE;
  v_new_valor_cuota   NUMBER(10);

  v_cnt_creditos_aa   NUMBER := 0;        
  
BEGIN
  v_anio_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

  -- 1) Validar que el crédito pertenezca al cliente y obtener tipo (nombre_credito)
  SELECT cr.nombre_credito
    INTO v_nombre_credito
    FROM credito_cliente cc
    JOIN credito cr
      ON cr.cod_credito = cc.cod_credito
   WHERE cc.nro_solic_credito = b_nro_solic_credito
     AND cc.nro_cliente       = b_nro_cliente;

  -- 2) Obtener última cuota del crédito (nro_cuota mayor)
  SELECT q.nro_cuota, q.fecha_venc_cuota, q.valor_cuota
    INTO v_last_nro_cuota, v_last_fecha_venc, v_last_valor_cuota
    FROM cuota_credito_cliente q
   WHERE q.nro_solic_credito = b_nro_solic_credito
     AND q.nro_cuota = (SELECT MAX(nro_cuota)
                          FROM cuota_credito_cliente
                         WHERE nro_solic_credito = b_nro_solic_credito);

  -- 3) Determinar tasa según tipo de crédito y cantidad de cuotas a postergar
  --    Hipotecario:
  --      - 1 cuota: 0% (sin interés)
  --      - hasta 2 cuotas: 0,5% (0.005)
  --    Consumo:
  --      - 1 cuota: 1% (0.01)
  --    Automotriz:
  --      - 1 cuota: 2% (0.02)
  IF UPPER(v_nombre_credito) LIKE '%HIPOTEC%' THEN
    IF b_cant_cuotas = 1 THEN
      v_tasa := 0;
    ELSIF b_cant_cuotas = 2 THEN
      v_tasa := 0.005;
    ELSE
      RAISE_APPLICATION_ERROR(-20002, 'Crédito hipotecario permite postergar 1 o 2 cuotas. Cantidad='||b_cant_cuotas);
    END IF;

  ELSIF UPPER(v_nombre_credito) LIKE '%CONSUM%' THEN
    IF b_cant_cuotas != 1 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Crédito de consumo permite postergar solo 1 cuota. Cantidad='||b_cant_cuotas);
    END IF;
    v_tasa := 0.01;

  ELSIF UPPER(v_nombre_credito) LIKE '%AUTOM%' THEN
    IF b_cant_cuotas != 1 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Crédito automotriz permite postergar solo 1 cuota. Cantidad='||b_cant_cuotas);
    END IF;
    v_tasa := 0.02;

  ELSE
    RAISE_APPLICATION_ERROR(-20005, 'Tipo de crédito no reconocido para reglas de postergación: '||v_nombre_credito);
  END IF;

  -- 4) Regla adicional: si el cliente solicitó MÁS de 1 crédito en el año anterior,
  --    se condona la deuda de la última cuota del crédito (queda pagada).
  SELECT COUNT(*)
    INTO v_cnt_creditos_aa
    FROM credito_cliente cc
   WHERE cc.nro_cliente = b_nro_cliente
     AND EXTRACT(YEAR FROM cc.fecha_solic_cred) = v_anio_anterior;

  IF v_cnt_creditos_aa > 1 THEN
    UPDATE cuota_credito_cliente
       SET fecha_pago_cuota = fecha_venc_cuota,
           monto_pagado     = valor_cuota,
           saldo_por_pagar  = 0
     WHERE nro_solic_credito = b_nro_solic_credito
       AND nro_cuota         = v_last_nro_cuota;
  END IF;

  -- 5) Generar e insertar nueva(s) cuota(s)
  --    - nro_cuota correlativo desde la última cuota
  --    - fecha_venc = ADD_MONTHS(fecha_venc_ultima, i)
  --    - valor_cuota = valor_ultima_cuota * (1 + tasa)
  --    - monto_pagado, fecha_pago, saldo_por_pagar, forma_pago = NULL
  FOR i IN 1..b_cant_cuotas LOOP
    v_new_nro_cuota   := v_last_nro_cuota + i;
    v_new_fecha_venc  := ADD_MONTHS(v_last_fecha_venc, i);
    v_new_valor_cuota := ROUND(v_last_valor_cuota * (1 + v_tasa));

    INSERT INTO cuota_credito_cliente
      (nro_solic_credito, nro_cuota, fecha_venc_cuota, valor_cuota,
       fecha_pago_cuota, monto_pagado, saldo_por_pagar, cod_forma_pago)
    VALUES
      (b_nro_solic_credito, v_new_nro_cuota, v_new_fecha_venc, v_new_valor_cuota,
       NULL, NULL, NULL, NULL);
  END LOOP;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Caso 2.3 Julian');
  DBMS_OUTPUT.PUT_LINE(' Cliente='||b_nro_cliente||' | Credito='||b_nro_solic_credito||' | Tipo='||v_nombre_credito);
  DBMS_OUTPUT.PUT_LINE(' Postergadas='||b_cant_cuotas||' | Tasa='||TO_CHAR(v_tasa*100,'FM9990D00')||'%');
  DBMS_OUTPUT.PUT_LINE(' UltCuota='||v_last_nro_cuota||' ('||TO_CHAR(v_last_fecha_venc,'YYYY-MM-DD')||') Valor='||v_last_valor_cuota);
  IF v_cnt_creditos_aa > 1 THEN
    DBMS_OUTPUT.PUT_LINE(' Condona última cuota (cliente con '||v_cnt_creditos_aa||' créditos en año anterior '||v_anio_anterior||').');
  ELSE
    DBMS_OUTPUT.PUT_LINE(' No condona última cuota (cliente con '||v_cnt_creditos_aa||' crédito(s) en año anterior '||v_anio_anterior||').');
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: No existe el crédito '||b_nro_solic_credito||' para el cliente '||b_nro_cliente);
    RAISE;
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: Ya existen cuotas con ese nro_cuota para este crédito (posible re-ejecución sin limpiar).');
    DBMS_OUTPUT.PUT_LINE('Sugerencia: elimine cuotas generadas (nro_cuota > última original) o pruebe con otro crédito.');
    RAISE;
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);
    RAISE;
END;
/


