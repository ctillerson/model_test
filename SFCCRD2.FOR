      SUBROUTINE SFCCRD2( KOUNT,CARD,ISTAT )
C=====================================================================**
C          SFCCRD Module of the AERMET Meteorological Preprocessor
C
C     Purpose:  Processes the FREQ_SECT keyword for the secondary
C               surface characteristics
C
C     Initial Release:  December 1992
C
C     Revision History:
C          1/27/97  moved from ONSITE pathway
C
C          12/2008  copied SFCCRD routine to SFCCRD2 to process the 
C                   secondary surface characteristics
C
C     Programmed by: Pacific Environmental Services, Inc. (PES)
C                    Research Triangle Park, NC
C
C-----------------------------------------------------------------------

C-----Variable Declarations
             
      IMPLICIT  NONE
      CHARACTER CARD*(*)
      INTEGER   ISTAT,ITEST

      INCLUDE 'MAIN1.INC'
      INCLUDE 'MAIN2.INC'                      
      INCLUDE 'MP1.INC'
      INCLUDE 'MP2.INC'
      INCLUDE 'WORK1.INC'

C      ISTAT     PROCESS STATUS 1 = ERROR IN PROCESSING
C                               2 = PROCESSING OK
C      CARD      Runstream record 
C      SFCFRQ2   SAVED FREQUENCY SO THE VALUE CAN BE TESTED WHILE
C                PROCESSING SECTOR AND SITE_CHAR RECORDS
C                  0 = NO FREQ_SECT CARD SEEN
C                  1 = FREQ_SECT CARD SEEN, BUT HAD ERRORS
C                  2 = MONTHLY VALUES
C                  3 = SEASONAL VALUES
C                  4 = ANNUAL VALUES

C      NOTE, USER MUST DEFINE THE FREQ_SECT BEFORE SECTOR & SITE_CHAR
C            RECORDS

C-----Data Initialization

      PATH = 'METPREP'
      LOC  = 'SFCCRD2' 
      ISTAT = 0
      SFCFRQ2 = 0

C-----Check the number of fields: must be 3

      IF( NWORDS.LT.3 )THEN
         ECODE = 'E04'
         MESS =  BLNK80      
         WRITE( MESS,1000 )
1000     FORMAT(' Too few fields on ''FREQ_SECT2'' keyword.')
         CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
         ISTAT = 1
         SFCFRQ2 = 1
         RETURN
      ELSEIF( NWORDS .GT. 3 )THEN
         ECODE = 'E04'
         MESS =  BLNK80      
         WRITE( MESS,2000 )
2000     FORMAT(' Too many fields on ''FREQ_SECT2'' keyword.')
         CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
         ISTAT = 1
         SFCFRQ2 = 1
         RETURN
      ENDIF 

C-----User is over-riding internal default values; reinitialize 

      OSNWDS2 = 0
      NUMSEC2 = 0
C --- NOTE:  OSSFC2 is already initialized to -9 for QA purposes
      OSWDS2(:,:) = 0.0

C-----Fetch the second field: frequency = ANNUAL,SEASONAL,MONTHLY

      BUF08(1) = 'SFCFREQ2'
      BUF08(2) = BLNK08
      CALL GETWRD( 2,KOUNT,CARD,6,8,2,BUF08(1),BUF08(2),ITEST ) 
      ISTAT = ITEST
      IF( ITEST.EQ.2 )THEN
         IF( BUF08(2)(1:3).EQ.'MON' .AND. ISTAT.NE.1 )THEN
            SFCFRQ2 = 2
            NKFREQ2 = 12
         ELSEIF( BUF08(2)(1:3).EQ.'SEA' .AND. ISTAT.NE.1 )THEN
            SFCFRQ2 = 3
            NKFREQ2 = 4
         ELSEIF( BUF08(2)(1:3).EQ.'ANN' .AND. ISTAT.NE.1 )THEN
            SFCFRQ2 = 4
            NKFREQ2 = 1
         ENDIF
      ELSE
         ECODE = 'E07'
         MESS =  BLNK80
         WRITE( MESS,2500 )
2500     FORMAT(' ERROR FROM S.GETWRD: SECONDARY SFC CHAR FREQUENCY')
         CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
         ISTAT = 1
         RETURN
      ENDIF

      IF (SFCFRQ2 .EQ. 0) THEN
C------- The field did not match any of the valid values
         ECODE = 'E06' 
         MESS =  BLNK80
         WRITE( MESS,3000 ) BUF08(2)
3000     FORMAT(' Unknown frequency specified on ',
     &          '''FREQ_SECT2'' keyword: ', A8)
         CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
         ISTAT = 1
      ENDIF


C-----Fetch third field: # wind sectors (maximum of OSMSEC)

      BUF08(1) = ' OSNWDS2'
      BUF02    = '  '
      CALL GETWRD( 3,KOUNT,CARD,1,2,1,BUF08(1),BUF02,ITEST )

      IF( ITEST.EQ.2 )THEN
         READ( BUF02,4000,IOSTAT=IOFLAG ) OSNWDS2
4000     FORMAT( I2 )
         IF( IOFLAG.EQ.0 )THEN
C---------- Check value, see if reasonable (OSMSEC is the maximum
C           number of wind sectors and is defined in MP1.INC)

            IF( OSNWDS2 .GE. 1 .AND. OSNWDS2 .LE. OSMSEC )THEN
               IF( ISTAT .NE. 1) ISTAT = 2
            ELSE
               ECODE = 'E06'
               MESS =  BLNK80
               WRITE( MESS,4500 ) OSNWDS2
4500           FORMAT(' Invalid # of wind sectors specified ',
     &                 'on ''FREQ_SECT2'': ',I2)
               CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
               ISTAT = 1
            ENDIF

         ELSE
            ECODE = 'E06'
            MESS =  BLNK80
            WRITE( MESS,4600 ) BUF02
4600        FORMAT(' Error decoding # of wind sectors specified ',
     &                 'on ''FREQ_SECT2'' keyword: ',A2)
            CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
            ISTAT = 1

         ENDIF

      ELSE
         ECODE = 'E07'
         MESS =  BLNK80
         WRITE( MESS,4700 )
4700     FORMAT(' ERROR FROM S.GETWRD: # SECONDARY WIND SECTORS')
         CALL ERRHDL( KOUNT,PATH,ECODE,LOC,MESS )
         ISTAT = 1
         RETURN
      ENDIF
     
C-----Check ISTAT and set SFCFRQ2 if errors were encounterd and
C     set the number of wind direction sectors to zero
C     (so S.MPTEST does not generate an error message)
      IF( ISTAT .EQ. 1 )THEN
         SFCFRQ2 = 1
         OSNWDS2 = 0
      ENDIF

      RETURN
      END 

