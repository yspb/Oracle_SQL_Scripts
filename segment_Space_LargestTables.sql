col TABLE_NAME format a40
col owner format a10
SELECT /*+ OPT_PARAM('_OPTIMIZER_DISTINCT_AGG_TRANSFORM', 'FALSE') */ 
  NULL OWNER, NULL TABLE_NAME, NULL B, NULL POS, NULL TOTAL_GB, NULL "TOTAL_%", NULL "CUM_%", NULL "PART.",
  NULL TABLE_GB, NULL TAB_TABSPACE, NULL "IND.", NULL INDEX_GB,
  NULL IND_TABSPACE, NULL LOBS, NULL LOB_GB FROM DUAL WHERE 1 = 0
UNION ALL (
SELECT NULL OWNER, NULL TABLE_NAME, NULL B, NULL POS, NULL TOTAL_GB, NULL "TOTAL_%", NULL "CUM_%", NULL "PART.",
  NULL TABLE_GB, NULL TAB_TABSPACE, NULL "IND.", NULL INDEX_GB,
  NULL IND_TABSPACE, NULL LOBS, NULL LOB_GB FROM DUAL WHERE 1 = 0
) UNION ALL ( SELECT * FROM (
WITH BASIS_INFO AS
( SELECT /*+ MATERIALIZE */
    '%' TABLESPACE_NAME,
    '%' TABLE_NAME,
    100  NUM_RECORDS,
    -1 MIN_TOTAL_SIZE_MB,
    ' ' ONLY_BASIS_TABLES
  FROM
    DUAL
),
SEGMENTS AS
( SELECT /*+ MATERIALIZE */
    S.OWNER,
    S.SEGMENT_NAME,
    S.PARTITION_NAME,
    S.SEGMENT_TYPE,
    S.TABLESPACE_NAME,
    S.BYTES
  FROM
    BASIS_INFO BI,
    DBA_SEGMENTS S
  WHERE
    S.TABLESPACE_NAME LIKE BI.TABLESPACE_NAME
),
TOTAL_SEGMENT_SIZE AS
( SELECT /*+ MATERIALIZE */
    SUM(BYTES) DB_NET_SIZE_BYTE
  FROM
    SEGMENTS
),
INDEXES AS
( SELECT /*+ MATERIALIZE */
    OWNER,
    TABLE_NAME,
    INDEX_NAME,
    TABLESPACE_NAME
  FROM
    DBA_INDEXES
),
LOBS AS
( SELECT /*+ MATERIALIZE */
    OWNER,
    TABLE_NAME,
    SEGMENT_NAME,
    TABLESPACE_NAME, 
    INDEX_NAME,
    COLUMN_NAME
  FROM
    DBA_LOBS
),
TABLE_SEGMENT_MAPPING AS
( SELECT /*+ MATERIALIZE */
    OWNER,
    SEGMENT_NAME TABLE_NAME,
    TABLESPACE_NAME,
    'TABLE' SEGMENT_TYPE,
    1 SEGMENTS,
    SUM(DECODE(PARTITION_NAME, NULL, 0, 1)) PARTITIONS,
    SUM(BYTES) BYTES
  FROM
    SEGMENTS
  WHERE
    SEGMENT_TYPE IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
  GROUP BY
    OWNER,
    SEGMENT_NAME,
    TABLESPACE_NAME
  UNION ALL
  ( SELECT
      I.OWNER OWNER,
      I.TABLE_NAME TABLE_NAME,
      S.TABLESPACE_NAME TABLESPACE_NAME,
      'INDEX' SEGMENT_TYPE,
      COUNT(DISTINCT(I.INDEX_NAME)) SEGMENTS,
      SUM(DECODE(S.PARTITION_NAME, NULL, 0, 1)) PARTITIONS,
      SUM(S.BYTES) BYTES
    FROM
      SEGMENTS S,
      INDEXES I
    WHERE
      S.OWNER = I.OWNER AND
      S.SEGMENT_NAME = I.INDEX_NAME AND
      S.SEGMENT_TYPE IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION')
    GROUP BY
      I.OWNER,
      I.TABLE_NAME,
      S.TABLESPACE_NAME 
  )
  UNION ALL
  ( SELECT
      L.OWNER OWNER,
      L.TABLE_NAME TABLE_NAME,
      S.TABLESPACE_NAME TABLESPACE_NAME,
      'LOB' SEGMENT_TYPE,
      COUNT(DISTINCT(L.COLUMN_NAME)) SEGMENTS,
      SUM(DECODE(S.PARTITION_NAME, NULL, 0, 1)) PARTITIONS,
      SUM(S.BYTES) BYTES
    FROM
      SEGMENTS S,
      LOBS L
    WHERE
      S.OWNER = L.OWNER AND
      S.SEGMENT_NAME IN ( L.SEGMENT_NAME, L.INDEX_NAME ) AND
      S.SEGMENT_TYPE IN ('LOBSEGMENT', 'LOBINDEX', 'LOB PARTITION')
    GROUP BY
      L.OWNER,
      L.TABLE_NAME,
      S.TABLESPACE_NAME
  )
),
BASIS_TABLES AS
( SELECT /*+ MATERIALIZE */
    OWNER,
    TABLE_NAME
  FROM
    DBA_TABLES
  WHERE
    TABLE_NAME IN
    ( 'BALHDR', 'BALHDRP', 'BALM', 'BALMP', 'BALDAT', 'BALC', 
      'BAL_INDX', 'EDIDS', 'EDIDC', 'EDIDOC', 'EDI30C', 'EDI40',
      'IDOCREL', 'SRRELROLES', 'SWFGPROLEINST', 'SWP_HEADER', 'SWP_NODEWI', 'SWPNODE',
      'SWPNODELOG', 'SWPSTEPLOG', 'SWW_CONT', 'SWW_CONTOB', 'SWW_WI2OBJ', 'SWWCNTP0',
      'SWWCNTPADD', 'SWWEI', 'SWWLOGHIST', 'SWWLOGPARA', 'SWWWIDEADL', 'SWWWIHEAD', 
      'SWWWIRET', 'SWZAI', 'SWZAIENTRY', 'SWZAIRET', 'SWWUSERWI',                  
      'BDCP', 'BDCPS', 'BDCP2', 'DBTABLOG', 'DBTABPRT', 
      'ARFCSSTATE', 'ARFCSDATA', 'ARFCRSTATE', 'TRFCQDATA',
      'TRFCQIN', 'TRFCQOUT', 'TRFCQSTATE', 'SDBAH', 'SDBAD', 'DBMSGORA', 'DDLOG',
      'APQD', 'TST01', 'TST03', 'TSPEVJOB', 'TXMILOGRAW', 'TSPEVDEV', 
      'SNAP', 'SMO8FTCFG', 'SMO8FTSTP', 'SMO8_TMSG', 'SMO8_TMDAT', 
      'SMO8_DLIST', 'SMW3_BDOC', 'SMW3_BDOC1', 'SMW3_BDOC2', 
      'SMW3_BDOC4', 'SMW3_BDOC5', 'SMW3_BDOC6', 'SMW3_BDOC7', 'SMW3_BDOCQ', 'SMWT_TRC',
      'TPRI_PAR', 'RSMONMESS', 'RSSELDONE', 'VBDATA', 'VBMOD', 'VBHDR', 'VBERROR',
      'VDCHGPTR', 'JBDCPHDR2', 'JBDCPPOS2', 'SWELOG', 'SWELTS', 'SWFREVTLOG',
      'ARDB_STAT0', 'ARDB_STAT1', 'ARDB_STAT2', 'QRFCTRACE', 'QRFCLOG',
      'DDPRS', 'TBTCO', 'TBTCP', 'MDMFDBEVENT', 'MDMFDBID', 'MDMFDBPR',
      'RSRWBSTORE', '"/SAPAPO/LISMAP"', '"/SAPAPO/LISLOG"', 
      'CCMLOG', 'CCMLOGD', 'CCMSESSION', 'CCMOBJLST', 'CCMOBJKEYS',
      'SXMSPMAST', 'SXMSPMAST2', 'SXMSPHIST', 'RSBATCHDATA',
      'SXMSPHIST2', 'SXMSPFRAWH', 'SXMSPFRAWD', 'SXMSCLUR', 'SXMSCLUR2', 'SXMSCLUP',
      'SXMSCLUP2', 'SWFRXIHDR', 'SWFRXICNT', 'SWFRXIPRC', 'XI_AF_MSG', 
      'XI_AF_MSG_AUDIT', 'SMW0REL', 'SRRELROLES', 'COIX_DATA40', 'T811E', 'T811ED', 
      'T811ED2', 'RSDDSTATAGGR', 'RSDDSTATAGGRDEF', 'RSDDSTATCOND', 'RSDDSTATDTP',
      'RSDDSTATDELE', 'RSDDSTATDM', 'RSDDSTATEVDATA', 'RSDDSTATHEADER',
      'RSDDSTATINFO', 'RSDDSTATLOGGING', 'RSERRORHEAD', 'RSERRORLOG',
      'DFKKDOUBTD_W', 'DFKKDOUBTD_RET_W', 'RSBERRORLOG', 'INDX',
      'SOOD', 'SOOS', 'SOC3', 'SOFFCONT1', 'BCST_SR', 'BCST_CAM',
      'SICFRECORDER', 'CRM_ICI_TRACES', 'RSPCINSTANCE',
      'GVD_BGPROCESS', 'GVD_BUFF_POOL_ST', 'GVD_LATCH_MISSES', 
      'GVD_ENQUEUE_STAT', 'GVD_FILESTAT', 'GVD_INSTANCE',    
      'GVD_PGASTAT', 'GVD_PGA_TARGET_A', 'GVD_PGA_TARGET_H',
      'GVD_SERVERLIST', 'GVD_SESSION_EVT', 'GVD_SESSION_WAIT',
      'GVD_SESSION', 'GVD_PROCESS', 'GVD_PX_SESSION',  
      'GVD_WPTOTALINFO', 'GVD_ROWCACHE', 'GVD_SEGMENT_STAT',
      'GVD_SESSTAT', 'GVD_SGACURRRESIZ', 'GVD_SGADYNFREE',  
      'GVD_SGA', 'GVD_SGARESIZEOPS', 'GVD_SESS_IO',     
      'GVD_SGASTAT', 'GVD_SGADYNCOMP', 'GVD_SEGSTAT',     
      'GVD_SPPARAMETER', 'GVD_SHAR_P_ADV', 'GVD_SQLAREA',     
      'GVD_SQL', 'GVD_SQLTEXT', 'GVD_SQL_WA_ACTIV',
      'GVD_SQL_WA_HISTO', 'GVD_SQL_WORKAREA', 'GVD_SYSSTAT',     
      'GVD_SYSTEM_EVENT', 'GVD_DATABASE', 'GVD_CURR_BLKSRV', 
      'GVD_DATAGUARD_ST', 'GVD_DATAFILE', 'GVD_LOCKED_OBJEC',
      'GVD_LOCK_ACTIVTY', 'GVD_DB_CACHE_ADV', 'GVD_LATCHHOLDER', 
      'GVD_LATCHCHILDS', 'GVD_LATCH', 'GVD_LATCHNAME',   
      'GVD_LATCH_PARENT', 'GVD_LIBRARYCACHE', 'GVD_LOCK',        
      'GVD_MANGD_STANBY', 'GVD_OBJECT_DEPEN', 'GVD_PARAMETER',   
      'GVD_LOGFILE', 'GVD_PARAMETER2', 'GVD_TEMPFILE',    
      'GVD_UNDOSTAT', 'GVD_WAITSTAT', 'ORA_SNAPSHOT',
      '/TXINTF/TRACE', 'RSECLOG', 'RSECUSERAUTH_CL', 'RSWR_DATA',
      'RSECVAL_CL', 'RSECHIE_CL', 'RSECTXT_CL', 'RSECSESSION_CL',
      'UPC_STATISTIC', 'UPC_STATISTIC2', 'UPC_STATISTIC3'
    ) OR
    TABLE_NAME LIKE '/BI0/0%'
),
LINES AS
( SELECT 1 LINENR, 'TOTAL' DESCRIPTION FROM DUAL UNION ALL
  ( SELECT 2 LINENR, 'TABLE' DESCRIPTION FROM DUAL ) UNION ALL
  ( SELECT 3 LINENR, 'INDEX' DESCRIPTION FROM DUAL ) UNION ALL
  ( SELECT 4 LINENR, 'LOB' DESCRIPTION FROM DUAL )
)
SELECT
  D.OWNER,
  D.TABLE_NAME,
  DECODE(D.BASIS_TABLE, NULL, ' ', 'X') B,
  TO_CHAR(ROWNUM, 990) POS,
  TO_CHAR(TOTAL_BYTES / 1024 / 1024 / 1024, 99990.99) TOTAL_GB,
  TO_CHAR(TOTAL_BYTES / DB_NET_SIZE_BYTE * 100, 990.99) "TOTAL_%", 
  TO_CHAR(SUM(TOTAL_BYTES / DB_NET_SIZE_BYTE * 100) OVER (ORDER BY TOTAL_BYTES DESC
    RANGE UNBOUNDED PRECEDING), 990.99) "CUM_%",
  TO_CHAR("PART.", 9990) "PART.",
  TO_CHAR(TAB_BYTES / 1024 / 1024 / 1024, 99990.99) TABLE_GB,
  TAB_TABSPACE,
  TO_CHAR("INDEXES", 990) "IND.",
  TO_CHAR(IND_BYTES / 1024 / 1024 / 1024, 9990.99) INDEX_GB,
  IND_TABSPACE,
  TO_CHAR(LOBS, 990) LOBS,
  TO_CHAR(LOB_BYTES / 1024 / 1024 / 1024, 9990.99) LOB_GB
FROM
( SELECT
    OWNER,
    TABLE_NAME,
    MAX(BASIS_TABLE) BASIS_TABLE,
    SUM(DECODE(COMPONENT, 'TOTAL', BYTES, 0)) TOTAL_BYTES,
    SUM(DECODE(COMPONENT, 'TABLE', COUNTER, 0)) "PART.",
    SUM(DECODE(COMPONENT, 'TABLE', BYTES, 0)) TAB_BYTES,
    MAX(DECODE(COMPONENT, 'TABLE', TABLESPACE_NAME)) TAB_TABSPACE,
    SUM(DECODE(COMPONENT, 'INDEX', COUNTER, 0)) "INDEXES",
    SUM(DECODE(COMPONENT, 'INDEX', BYTES, 0)) IND_BYTES,
    MAX(DECODE(COMPONENT, 'INDEX', TABLESPACE_NAME)) IND_TABSPACE,
    SUM(DECODE(COMPONENT, 'LOB',   COUNTER, 0)) LOBS,
    SUM(DECODE(COMPONENT, 'LOB',   BYTES, 0)) LOB_BYTES
  FROM
  ( SELECT
      TSM.OWNER OWNER,
      TSM.TABLE_NAME TABLE_NAME,
      BT.TABLE_NAME BASIS_TABLE,
      L.DESCRIPTION COMPONENT,
     DECODE(L.DESCRIPTION, 
        'TOTAL', MAX(DECODE(TSM.SEGMENT_TYPE, 'TABLE', TSM.TABLESPACE_NAME)), 
        'TABLE', MAX(DECODE(TSM.SEGMENT_TYPE, 'TABLE', TSM.TABLESPACE_NAME)),
        'INDEX', MAX(DECODE(TSM.SEGMENT_TYPE, 'INDEX', TSM.TABLESPACE_NAME)),
        'LOB',   MAX(DECODE(TSM.SEGMENT_TYPE, 'LOB',   TSM.TABLESPACE_NAME))) TABLESPACE_NAME,
      DECODE(L.DESCRIPTION, 
        'TOTAL', SUM(TSM.BYTES), 
        'TABLE', SUM(DECODE(TSM.SEGMENT_TYPE, 'TABLE', TSM.BYTES)),
        'INDEX', SUM(DECODE(TSM.SEGMENT_TYPE, 'INDEX', TSM.BYTES)),
        'LOB',   SUM(DECODE(TSM.SEGMENT_TYPE, 'LOB',   TSM.BYTES))) BYTES,
      DECODE(L.DESCRIPTION,
        'TOTAL', 0,
        'TABLE', SUM(DECODE(TSM.SEGMENT_TYPE, 'TABLE', TSM.PARTITIONS)),
        'INDEX', SUM(DECODE(TSM.SEGMENT_TYPE, 'INDEX', TSM.SEGMENTS)),
        'LOB',   SUM(DECODE(TSM.SEGMENT_TYPE, 'LOB',   TSM.SEGMENTS))) COUNTER
    FROM
      BASIS_INFO BI,
      TABLE_SEGMENT_MAPPING TSM,
      LINES L,
      BASIS_TABLES BT
    WHERE
      TSM.TABLE_NAME LIKE BI.TABLE_NAME AND
      TSM.TABLE_NAME = BT.TABLE_NAME (+)
    GROUP BY
      L.LINENR,
      L.DESCRIPTION,
      TSM.OWNER,
      TSM.TABLE_NAME,
      BT.TABLE_NAME
    ORDER BY
      SUM(TSM.BYTES),
      TSM.TABLE_NAME,
      L.LINENR 
  )
  GROUP BY
    OWNER,
    TABLE_NAME
  ORDER BY
    4 DESC
) D,
TOTAL_SEGMENT_SIZE TSS,
BASIS_INFO BI
WHERE
  ( BI.ONLY_BASIS_TABLES = ' ' OR D.BASIS_TABLE IS NOT NULL ) AND
  ( BI.NUM_RECORDS = -1 OR ROWNUM <= BI.NUM_RECORDS ) AND
  ( BI.MIN_TOTAL_SIZE_MB = -1 OR TOTAL_BYTES / 1024 / 1024 >= BI.MIN_TOTAL_SIZE_MB )
));

