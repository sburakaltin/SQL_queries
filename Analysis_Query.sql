
CREATE PROCEDURE [dbo].[PROC_OPC] @COMPANYID INT, @CPERIODID INT, @SD DATE, @ED DATE
AS BEGIN

DECLARE @STARTDATE DATE, @ENDDATE DATE
SET @STARTDATE = @SD--Parameter Sniffing
SET @ENDDATE = @ED

DECLARE @OPC TABLE(RECEIPTID INT)
	
INSERT INTO @OPC
SELECT DISTINCT RECEIPTID FROM OPCMMAVALUES WHERE COMPANYID = @COMPANYID AND TRANSDATE BETWEEN @STARTDATE AND @ENDDATE

INSERT INTO OPCMMAVALUES
SELECT PR.COMPANYID, 
	   PR.PWORKSTATIONID,
	   PR.RECEIPTID, 
	   DP.OPCTAGDEFID, 
	   PR.PID,
	   PR.TRANSDATE,
	   ISNULL(MIN(TAGVALUEFLOAT),0) MINVALUE,
	   ISNULL(MAX(TAGVALUEFLOAT),0) MAXVALUE,
	   ISNULL(AVG(TAGVALUEFLOAT),0) AVGVALUE,
	   GETDATE() INSERTDATE
FROM PRECEIPTOT PR WITH(NOLOCK, INDEX(IX_PRECEIPTOT_6))
	INNER JOIN PIDRECEIPT P WITH(NOLOCK, INDEX(IX_PIDRECEIPT_5)) ON PR.COMPANYID = P.COMPANYID AND PR.RECEIPTID = P.PRORECEIPTID
	INNER JOIN PORT_DEFINITION DP WITH(NOLOCK) ON PR.COMPANYID = DP.COMPANYID AND PR.PWORKSTATIONID = DP.PWORKSTATIONID
    INNER JOIN OPCTAGRESULT OP WITH(NOLOCK, INDEX(IX_OPCTAGRESULT_1)) ON DP.COMPANYID = OP.COMPANYID AND DP.OPCTAGDEFID = OP.OPCTAGDEFID AND OP.INSERTDATE BETWEEN P.JOBSTARTTIME AND P.INSERTDATE
WHERE PR.COMPANYID = @COMPANYID 
	  AND PR.CPERIODID = @CPERIODID
	  AND PR.TRANSDATE BETWEEN @STARTDATE AND @ENDDATE
	  AND PR.RECEIPTID NOT IN (SELECT * FROM @OPC)
GROUP BY PR.COMPANYID, 
	PR.PWORKSTATIONID, 
	PR.PID, 
	PR.TRANSDATE,
	PR.RECEIPTID, 
	DP.OPCTAGDEFID
ORDER BY PWORKSTATIONID, 
	RECEIPTID
END
