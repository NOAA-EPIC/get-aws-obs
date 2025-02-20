obtyp_default="all"
YYYYMMDDHH=${1:-$analdate}
OUTPATH=${2:-$obs_datapath}
obtyp=${3:-$obtyp_default} # specify single ob type, default is all obs.
nbackmax=${nbackmax:-10}
dryrun=${dryrun:="false"} # if "true", just print aws download command, check to see if file exists on aws

which aws
if [ $? -ne 0 ]; then
   echo "SLURM_CLUSTER_NAME=$SLURM_CLUSTER_NAME machine=${machine}"
   if [ $SLURM_CLUSTER_NAME == 'es' ]; then 
      if [ $machine == "gaeac5" ]; then
         module use /ncrc/proj/epic/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
      elif [ $machine == "gaeac6" ]; then
         module use /ncrc/proj/epic/spack-stack/c6/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
      fi
      module load stack-intel
      module load awscli-v2
   elif [ $SLURM_CLUSTER_NAME == 'hercules' ]; then
      module purge
      module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core 
      module load stack-intel/2021.9.0
      module load awscli-v2
   elif [ $SLURM_CLUSTER_NAME == 'hera' ]; then
      module purge
      module use /scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.6.0/envs/unified-env-rocky8/install/modulefiles/Core 
      module load stack-intel/2021.5.0
      module load awscli-v2
   else
      echo "cluster must be 'hera', 'hercules' or 'es' (gaea)"
      exit 1
   fi
fi
which aws
if [ $? -ne 0 ]; then
   echo "awscli not found"
   exit 1
fi

NNJA_PRVIATE_PROFILE=nnja-private-eumetsat-read

YYYYMM=`echo $YYYYMMDDHH | cut -c1-6`
YYYYMMDD=`echo $YYYYMMDDHH | cut -c1-8`
HH=`echo $YYYYMMDDHH | cut -c9-10`
DD=`echo $YYYYMMDDHH | cut -c7-8`
MM=`echo $YYYYMMDDHH | cut -c5-6`
YYYY=`echo $YYYYMMDDHH | cut -c1-4`
CDUMP='gdas'
S3PATH=/noaa-reanalyses-pds/observations/reanalysis
S3PATH_PRIVATE=/nnja-private-eumetsat/observations/reanalysis
# directory structure required by global-workflow
TARGET_DIR=${OUTPATH}/${CDUMP}.${YYYYMMDD}/${HH}/atmos
mkdir -p $TARGET_DIR
obtypes=("airs" "amsua" "amsua" "amsub" "amv" "atms" "cris" "cris" "geo" "geo" "geo" "geo" "gps" "hirs" "hirs" "hirs" "iasi" "mhs" "msu" "saphir" "seviri" "ssmi" "ssmis" "ssu")
dirs=("nasa" "nasa" "1bamua" "1bamub" "satwnd" "atms" "cris" "crisf4" "goesnd" "goesfv" "gsrcsr" "ahicsr" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "ssmit" "ssmisu" "1bssu")
obnames=("aqua" "aqua" "1bamua" "1bamub" "satwnd" "atms" "cris" "crisf4" "goesnd" "goesfv" "gsrcsr" "ahicsr" "gpsro" "1bhrs2" "1bhrs3" "1bhrs4" "mtiasi" "1bmhs" "1bmsu" "saphir" "sevcsr" "ssmit" "ssmisu" "1bssu")
dumpnames=("airs_disc_final" "amsua_disc_final" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas" "gdas")
nback=0
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     if [ ${obtypes[$n]} == "airs" ] && [ ${dirs[$n]} == "nasa" ]; then
        # NASA airs obs
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.bufr"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.airsev.tm00.bufr_d"
     #elif [ ${obtypes[$n]} == "airs" ] && [ ${dirs[$n]} == "airsev" ]; then
     #   # obtype=airs obname=airsev dir=airsev dumpname=gdas
     #   # amsua data from NCEP airsev file
     #   s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     #   localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.aquaamua.tm00.bufr_d"
     elif [ ${obtypes[$n]} == "amsua" ] && [ ${dirs[$n]} == "nasa" ]; then
        # obtype=amsua obname=aqua dir=nasa dumpname=amsua_disc_final
        # NASA airs obs
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.bufr"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.aquaamua.tm00.bufr_d"
     elif [ ${obtypes[$n]} == "amsua" ] && [ ${dirs[$n]} == "nasa/r21c_repro" ]; then
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.1bamua.tm00.bufr_d"
     else
        s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
        localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     fi
     nback=$[$nback+1]
     if [ $dryrun == "true" ]; then
         echo "aws s3 cp --no-sign-request --only-show-errors $s3file $localfile"
         aws s3 ls --no-sign-request $s3file
	 if [ $? -ne 0 ]; then
             echo "$s3file not found"
	 fi
     else
         aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
         if [ $nback -eq $nbackmax ]; then
            wait
            nback=0
         fi
     fi
     #ls -l $localfile
  fi
done
wait
# prepbufr
obtypes="prepbufr prepbufr.acft_profiles"
for obtype in $obtypes; do
   if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
      if [ $obtype == "prepbufr" ]; then
         s3file=s3:/"${S3PATH}/conv/${obtype}/${YYYY}/${MM}/prepbufr/gdas.${YYYYMMDD}.t${HH}z.${obtype}.nr"
      else
         s3file=s3:/"${S3PATH}/conv/${obtype}/${YYYY}/${MM}/bufr/gdas.${YYYYMMDD}.t${HH}z.${obtype}.nr"
      fi
      localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obtype}"
      #aws s3 ls --no-sign-request $s3file
      if [ $dryrun == "true" ]; then
          echo "aws s3 cp --no-sign-request --only-show-errors $s3file $localfile"
          aws s3 ls --no-sign-request $s3file
	  if [ $? -ne 0 ]; then
             echo "$s3file not found"
	  fi
      else
          aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
      fi
      #ls -l $localfile
   fi
done
# ozone
# CFSR
if [ $obtyp == "osbuv8" ] || [ $obtyp == "all" ]; then
   s3file=s3:/"${S3PATH}/ozone/cfsr/${YYYY}/${MM}/bufr/gdas.${YYYYMMDD}.t${HH}z.osbuv8.tm00.bufr_d"
   localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.osbuv8.tm00.bufr_d"
   #aws s3 ls --no-sign-request $s3file
   if [ $dryrun == "true" ]; then
      echo "aws s3 cp --no-sign-request --only-show-errors $s3file $localfile"
      aws s3 ls --no-sign-request $s3file
      if [ $? -ne 0 ]; then
         echo "$s3file not found"
      fi
   else
      aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
   fi
   #ls -l $localfile
fi
# NCEP bufr
obtypes=("ozone" "ozone" "ozone")
dirs=("ncep" "ncep" "ncep")
obnames=("ompslp" "ompsn8" "ompst8")
dumpnames=("gdas" "gdas" "gdas")
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[n]}/${YYYY}/${MM}/bufr/${dumpnames[$n]}.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     #aws s3 ls --no-sign-request $s3file
     if [ $dryrun == "true" ]; then
        echo "aws s3 cp --no-sign-request --only-show-errors $s3file $localfile"
        aws s3 ls --no-sign-request $s3file
	if [ $? -ne 0 ]; then
           echo "$s3file not found"
	fi
     else
        aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
     fi
     #ls -l $localfile
  fi
done
# NASA bufr
if [ $obtyp == "sbuv_v87" ] || [ $obtyp == "all" ]; then
   s3file=s3:/"${S3PATH}/ozone/nasa/sbuv_v87/${YYYY}/${MM}/bufr/sbuv_v87.${YYYYMMDD}.${HH}z.bufr"
   localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.sbuv_v87.tm00.bufr_d"
   #aws s3 ls --no-sign-request $s3file
   if [ $dryrun == "true" ]; then
      echo "aws s3 cp --no-sign-request --only-show-errors $s3file $localfile"
      aws s3 ls --no-sign-request $s3file
      if [ $? -ne 0 ]; then
         echo "$s3file not found"
      fi
   else
      aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
   fi
   #ls -l $localfile
fi
# NASA netcdf
obtypes=("ozone" "ozone" "ozone" "ozone" "ozone")
dirs=("nasa" "nasa" "nasa" "nasa" "nasa")
obnames=("mls" "omi-eff" "omps-lp" "omps-nm-eff" "omps-nm")
dumpnames=("MLS-v5.0-oz" "OMIeff-adj" "OMPS-LPoz-Vis" "OMPSNM" "OMPSNP")
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     s3file=s3:/"${S3PATH}/${obtypes[$n]}/${dirs[$n]}/${obnames[$n]}/${YYYY}/${MM}/netcdf/${dumpnames[$n]}.${YYYYMMDD}_${HH}z.nc"
     localfile="${TARGET_DIR}/${dumpnames[$n]}.${YYYYMMDD}_${HH}z.nc"
     #aws s3 ls --no-sign-request $s3file
     if [ $dryrun == "true" ]; then
        echo "aws s3 cp --no-sign-request --only-show-errors $s3file $localfile"
        aws s3 ls --no-sign-request $s3file
	if [ $? -ne 0 ]; then
           echo "$s3file not found"
	fi
     else
        aws s3 cp --no-sign-request --only-show-errors $s3file $localfile &
     fi
     #ls -l $localfile
  fi
done
wait
# over-write with private eumetsat data if available
obtypes=("gps" "ssmi" "amv" "ssmis")
dirs=("eumetsat" "eumetsat" "merged" "eumetsat")
obnames=("gpsro" "ssmit" "satwnd" "ssmisu")
for n in ${!obtypes[@]}; do
  if [ ${obtypes[$n]} == $obtyp ] || [ $obtyp == "all" ]; then
     s3file=s3:/"${S3PATH_PRIVATE}/${obtypes[$n]}/${dirs[$n]}/${YYYY}/${MM}/bufr/gdas.${YYYYMMDD}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     localfile="${TARGET_DIR}/${CDUMP}.t${HH}z.${obnames[$n]}.tm00.bufr_d"
     if [ $dryrun == "true" ]; then
        echo "aws s3 cp --profile ${NNJA_PRVIATE_PROFILE} --only-show-errors $s3file $localfile"
        aws s3 ls --profile ${NNJA_PRVIATE_PROFILE} $s3file
	if [ $? -ne 0 ]; then
            echo "$s3file not found"
	fi
     else
        aws s3 cp --profile ${NNJA_PRVIATE_PROFILE} --only-show-errors $s3file $localfile &
     fi
  fi
done
wait
if [ $dryrun != "true" ]; then
   ls -l ${TARGET_DIR}
fi
