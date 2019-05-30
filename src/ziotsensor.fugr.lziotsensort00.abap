*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 20.02.2019 at 10:24:30
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZIOTSENSOR......................................*
DATA:  BEGIN OF STATUS_ZIOTSENSOR                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZIOTSENSOR                    .
CONTROLS: TCTRL_ZIOTSENSOR
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZIOTSENSOR                    .
TABLES: ZIOTSENSOR                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
