import os
import time
import sys
#import requests
#import json
#import base64
import getopt
import subprocess
from pathlib import Path

#----------------------------------------------------------------------------------------------------------------
class FetchAWSobs():
    def __init__(self, obtyp=obtyp, OUTPATH='.',
                 YYYYMMMDDHH=2024010100, nbackmax=10,
                 dryrun=0, verbose=0):

        self.obtyp = obtyp
        self.OUTPATH = OUTPATH
        self.YYYYMMMDDHH = YYYYMMMDDHH
        self.nbackmax = nbackmax
        self.dryrun = dryrun
        self.verbose = verbose

       #if (os.path.isdir(OUTPATH)):
       #    print('Prepare to download AWS obs to %s' %(OUTPATH))
       #else:
       #    print('local dir: <%s> does not exist. Stop' %(OUTPATH))
       #    sys.exit(-1)

        self.verdict = {}
        self.s3dict = {}
        self.s3dict['raworog'] = 'raw/orog'

        if (self.localdir.find('fix') < 0):
            self.targetdir = '%s/fix.subset' %(self.localdir)
        else:
            self.targetdir = self.OUTPATH

        self.set_default()

#----------------------------------------------------------------------------------------------------------------
    def set_default(self):
        self.CDUMP='gdas'
        self.S3PATH=/noaa-reanalyses-pds/observations/reanalysis
        self.S3PATH_PRIVATE=/nnja-private-eumetsat/observations/reanalysis

       #directory structure required by global-workflow
       #self.TARGET_DIR=${OUTPATH}/${CDUMP}.${YYYYMMDD}/${HH}/atmos
        self.obtypes = ['airs', 'amsua', 'amsua', 'amsub', 'amv', 'atms',
                        'cris', 'cris', 'geo', 'geo', 'geo', 'geo', 'gps',
                        'hirs', 'hirs', 'hirs', 'iasi', 'mhs', 'msu',
                        'saphir', 'seviri', 'ssmi', 'ssmis', 'ssu')
        self.dirs = ['nasa', 'nasa', '1bamua', '1bamub', 'satwnd',
                     'atms', 'cris', 'crisf4', 'goesnd', 'goesfv',
                     'gsrcsr', 'ahicsr', 'gpsro', '1bhrs2', '1bhrs3',
                     '1bhrs4', 'mtiasi', '1bmhs', '1bmsu', 'saphir',
                     'sevcsr', 'ssmit', 'ssmisu', '1bssu')
        self.obnames = ['aqua', 'aqua', '1bamua', '1bamub', 'satwnd',
                        'atms', 'cris', 'crisf4', 'goesnd', 'goesfv',
                        'gsrcsr', 'ahicsr', 'gpsro', '1bhrs2', '1bhrs3',
                        '1bhrs4', 'mtiasi', '1bmhs', '1bmsu', 'saphir',
                        'sevcsr', 'ssmit', 'ssmisu', '1bssu')
        self.dumpnames = ['airs_disc_final', 'amsua_disc_final',
                          'gdas', 'gdas', 'gdas', 'gdas', 'gdas', 'gdas',
                          'gdas', 'gdas', 'gdas', 'gdas', 'gdas', 'gdas',
                          'gdas', 'gdas', 'gdas', 'gdas', 'gdas', 'gdas',
                          'gdas', 'gdas', 'gdas', 'gdas')

#----------------------------------------------------------------------------------------------------------------
    def update_s3dict(self):
        self.update_s3dick_grid_independent()
        self.add_grid_data()

        if (self.verbose):
            self.printinfo()

#----------------------------------------------------------------------------------------------------------------
    def update_s3dick_grid_independent(self):
        for key in self.fix_ver_dict.keys():
            val = self.fix_ver_dict[key]
            if (key == 'aer_ver'):
                self.s3dict['aer'] = 'aer/%s' %(val)
            elif (key == 'am_ver'):
                self.s3dict['am'] = 'am/%s' %(val)
            elif (key == 'chem_ver'):
                self.s3dict['fimdata_chem'] = 'chem/%s/fimdata_chem' %(val)
                self.s3dict['Emission_data'] = 'chem/%s/Emission_data' %(val)
            elif (key == 'datm_ver'):
                self.s3dict['cfsr'] = 'datm/%s/cfsr' %(val)
                self.s3dict['gefs'] = 'datm/%s/gefs' %(val)
                self.s3dict['gfs'] = 'datm/%s/gfs' %(val)
                self.s3dict['mom6'] = 'datm/%s/mom6' %(val)
            elif (key == 'glwu_ver'):
                self.s3dict['glwu'] = 'glwu/%s' %(val)
            elif (key == 'gsi_ver'):
                self.s3dict['gsi'] = 'gsi/%s' %(val)
            elif (key == 'lut_ver'):
                self.s3dict['lut'] = 'lut/%s' %(val)
            elif (key == 'mom6_ver'):
                self.s3dict['mom6post'] = 'mom6/%s/post' %(val)
            elif (key == 'reg2grb2_ver'):
                self.s3dict['reg2grb2'] = 'reg2grb2/%s' %(val)
            elif (key == 'sfc_climb_ver'):
                self.s3dict['sfc_climo'] = 'sfc_climo/%s' %(val)
            elif (key == 'verif_ver'):
                self.s3dict['verif'] = 'verif/%s' %(val)
            elif (key == 'wave_ver'):
                self.s3dict['wave'] = 'wave/%s' %(val)

#----------------------------------------------------------------------------------------------------------------
    def add_grid_data(self):
        for key in self.fix_ver_dict.keys():
            val = self.fix_ver_dict[key]
            if (key == 'orog_ver'):
                self.add_atmgrid2s3dict('orog', key, val)
            elif (key == 'ugwd_ver'):
                self.add_atmgrid2s3dict('ugwd', key, val)
            elif (key == 'mom6_ver'):
                self.add_ocngrid2s3dict('mom6', key, val)
            elif (key == 'cice_ver'):
                self.add_ocngrid2s3dict('cice', key, val)
            elif (key == 'cpl_ver'):
                self.add_cpl2s3dict('cpl', key, val)

#----------------------------------------------------------------------------------------------------------------
    def add_atmgrid2s3dict(self, varname, key, val):
        for atmgrid in self.atmgridarray:
            newkey = '%s_%s' %(key, atmgrid)
            self.s3dict[newkey] = '%s/%s/%s' %(varname, val, atmgrid)

#----------------------------------------------------------------------------------------------------------------
    def add_ocngrid2s3dict(self, varname, key, val):
        for ocngrid in self.ocngridarray:
            newkey = '%s_%s' %(key, atmgrid)
            self.s3dict[newkey] = '%s/%s/%s' %(varname, val, ocngrid)

#----------------------------------------------------------------------------------------------------------------
    def add_cpl2s3dict(self, varname, key, val):
        for atmgrid in self.atmgridarray:
            for ocngrid in self.ocngridarray:
                newkey = '%s_a%so%s' %(key, atmgrid, ocngrid)
                self.s3dict[newkey] = '%s/%s/a%so%s' %(varname, val, atmgrid, ocngrid)

#----------------------------------------------------------------------------------------------------------------
    def printinfo(self):
        print('Preparing to fetch')
        print('ATM grid: ', self.atmgridarray)
        print('ONC grid: ', self.ocngridarray)
        print('From: %s' %(self.aws_fix_bucket))
        print('To: %s' %(self.targetdir))
        for key in self.s3dict.keys():
            val = self.s3dict[key]
            print('%s: %s' %(key, val))

#----------------------------------------------------------------------------------------------------------------
    def fetchdata(self):
        if (self.verbose):
            print('Create local fix dir: ', self.targetdir)

        path = Path(self.targetdir)
        path.mkdir(parents=True, exist_ok=True)

        self.fetch_ugwp_limb_tau()
        
        for key in self.s3dict.keys():
            self.fetch_dir(self.s3dict[key])

#----------------------------------------------------------------------------------------------------------------
    def fetch_dir(self, dir):
        remotedir = '%s/%s' %(self.aws_fix_bucket, dir)
        localdir = '%s/%s' %(self.targetdir, dir)
        cmd = '%s %s %s'%(self.aws_sync, remotedir, localdir)
        self.download_dir(cmd, localdir)

#----------------------------------------------------------------------------------------------------------------
    def download_dir(self, cmd, localdir):
       #returned_value = os.system(cmd)  # returns the exit code in unix
       #print('returned value:', returned_value)

        if (os.path.isdir(localdir)):
            print('%s already exist. skip' %(localdir))
        else:
            parentdir, dirname = os.path.split(localdir)
            if (self.verbose):
                print('Create local %s dir: ', parentdir)
           #path = Path(parentdir)
           #path.mkdir(parents=True, exist_ok=True)
            if (self.verbose):
                print(cmd)
            print('Downloading ', localdir)
           #returned_value = subprocess.call(cmd, shell=True)  # returns the exit code in unix
           #if (self.verbose):
           #    print('returned value:', returned_value)

#----------------------------------------------------------------------------------------------------------------
    def fetch_ugwp_limb_tau(self):
        ugwp_limb_tau_remotepath = '%s/ugwd/%s/ugwp_limb_tau.nc' %(self.aws_fix_bucket, self.ugwd_ver)
        ugwp_limb_tau_localdir = '%s/ugwd/%s' %(self.targetdir, self.ugwd_ver)
        filename = '%s/ugwp_limb_tau.nc' %(ugwp_limb_tau_localdir)
        path = Path(ugwp_limb_tau_localdir)
        path.mkdir(parents=True, exist_ok=True)
        cmd = '%s %s %s'%(self.aws_cp, ugwp_limb_tau_remotepath, filename)
        self.download_file(cmd, filename)

#----------------------------------------------------------------------------------------------------------------
    def download_file(self, cmd, filename):
       #returned_value = os.system(cmd)  # returns the exit code in unix
       #print('returned value:', returned_value)

        if (os.path.isfile(filename)):
            print('%s already exist. skip' %(filename))
        else:
            if (self.verbose):
                print(cmd)
            print('Downloading ', filename)
            returned_value = subprocess.call(cmd, shell=True)  # returns the exit code in unix
            if (self.verbose):
                print('returned value:', returned_value)

#----------------------------------------------------------------------------------------------------------------
    def set_fix_ver_from_gwhome(gwhome, verdict):
        fix_ver_file = '%s/versions/fix.ver'
        self.fix_ver_dict = verdict
        if (os.path.isfile(filename)):
            with open(fix_ver_file, 'r') as file:
                for line in file.readlines():
                    if (line.find('export ') >= 0):
                        headstr, _, value = line.strip().partition('=')
                        exphead, _, key = headstr.partition(' ')
                        self.fix_ver_dict[key] = value
        else:
            print('fix_ver_file: %s does not exist.' %(fix_ver_file))

#----------------------------------------------------------------------------------------------------------------
    def set_default_fix_ver(self, verdict):
        self.fix_ver_dict = verdict

#----------------------------------------------------------------------------------------------------------------
def print_usage(verdict):
    print('Usage: python fetch-fix-data.py \\')
    print('       --atmgrid=AtmospericGrid (for multiple grids, separate with ',') \\')
    print('       --ocngrid=OceanGrid (for multiple grids, separate with ',') \\')
    print('       --localdir=Your-local-fix-dir \\')
    print('       [options]')
    print('options are:')
    print('\t--gwhome=xxxx (Global-Workflow directory)')

    for key in verdict.keys():
        print('\t--%s=yyyymmdd  default: %s' %(key, verdict[key]))

#----------------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
    obtyp_default = 'all'
    YYYYMMDDHH = '20220805'
    OUTPATH = '/contrib/global-workflow-shared-data/awsobs'
    obtyp = obtyp_default
    nbackmax = 10
    dryrun = 0
    verbose = 0

    opts, args = getopt.getopt(sys.argv[1:], '', ['help', 'obtyp=', 'verbose=',
                                                  'nbackmax=',
                                                  'OUTPATH=',
                                                  'YYYYMMDDHH=',
                                                  'dryrun='])
    for o, a in opts:
        print('o: %s, a: %s' %(o, a))
        if o in ['--help']:
            print_usage(verdict)
            sys.exit(0)
        elif o in ['--verbose']:
            verbose = int(a)
        elif o in ['--dryrun']:
            dryrun = int(a)
        elif o in ['--obtyp']:
            obtyp = a
        elif o in ['--OUTPATH']:
            OUTPATH = a
        elif o in ['--YYYYMMDDHH']:
            YYYYMMDDHH = a
        else:
            print('Invalid option, o: %s, a: %s' %(o, a))

#------------------------------------------------------------------
    fao = FetchAWSobs(obtyp=obtyp, OUTPATH=OUTPATH,
                      YYYYMMMDDHH=YYYYMMMDDHH, nbackmax=nbackmax,
                      dryrun=dryrun, verbose=verbose)

    if (gwhome is None):
        ffd.set_default_fix_ver(verdict)
    else:
        ffd.set_fix_ver_from_gwhome(gwhome, verdict)

    ffd.update_s3dict()

    ffd.fetchdata()
