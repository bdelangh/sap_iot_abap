*&---------------------------------------------------------------------*
*& Report ZIOTALERT_DELETE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZIOTALERT_DELETE.

tables: ziotalert.

delete from ziotalert where alertid > 30.
