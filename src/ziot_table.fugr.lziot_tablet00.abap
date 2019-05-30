*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 05.02.2019 at 13:49:06
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZSENSOR_DATA....................................*
DATA:  BEGIN OF STATUS_ZSENSOR_DATA                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSENSOR_DATA                  .
CONTROLS: TCTRL_ZSENSOR_DATA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZSENSOR_DATA                  .
TABLES: ZSENSOR_DATA                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
