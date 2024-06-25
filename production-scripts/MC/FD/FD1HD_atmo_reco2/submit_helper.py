from argparse import ArgumentParser as ap
import subprocess

def upload_tar(tar):
  results = subprocess.run(
    ['justin-cvmfs-upload', tar],
    capture_output=True,
  )
    
  if results.returncode != 0:
    print('justin-cvmfs-upload error:', results.stderr.decode('UTF-8'))
    raise RuntimeError(f'Could not upload tar file named "{tar}" to cvmfs')

  return results.stdout.decode('UTF-8').strip()

def build_input(args):
  if is_hd(args):
    base = f'higuera:fardet-hd__fd_mc_he_2023a__mc__hit-reconstructed__prodgenie_atmnu_max_weighted_randompolicy_dune10kt_1x2x6.fcl__v09_79_00d02__preliminary'

  return base + f' skip {args.skip}' + (f' limit {args.limit} ordered' if args.limit is not None else '')

def build_output(args):

  types = [('*reco2.root', 'reco2')]

  outputs = [
    (f'{t[0]}:fardet-{args.det.lower()}-{t[1]}_ritm2032831_{args.flavor}_'
     f'skip{args.skip}' +
     (f'_limit{args.limit}' if args.limit is not None else '_end') +
     ('_test' if args.test else '') +
     ('_$JUSTIN_WORKFLOW_ID' if args.wid_out else '')
    )
    for t in types
  ]
  results = []
  for o in outputs:
    results.append('--output-pattern')
    results.append(f"'{o}'")
  return results 

def is_hd(args):
  return args.det.upper() == 'HD'

def is_vd(args):
  return args.det.upper() == 'VD'

def get_horn_current(args):
  return ('atm' if 'anu' in args.flavor else 'atm')

def check_flavor(args):
  hd_flavors = ['atmnu']
  if is_hd(args) and args.flavor not in hd_flavors:
    raise ValueError(f'Must choose flavor in {hd_flavors} when running HD')

if __name__ == '__main__':
  parser = ap()
  parser.add_argument('--script', type=str, default='dec2023_FD_MC_production.jobscript')
  parser.add_argument('--det', type=str, choices=['HD', 'VD', 'hd', 'vd'], default='HD')
  parser.add_argument('--flavor', type=str,
                      choices=['atmnu'],
                      default='nu')
  parser.add_argument('--test', action='store_true', help='Switch the scope to "usertests"')
  parser.add_argument('--wid_out', action='store_true', help='Add justin workflow id to end of output datasets')
  parser.add_argument('--no_out', action='store_true', help='Prevent output from being saved')
  parser.add_argument('--dset_postfix', type=str, default='', help='Postfix to give to the output pattern')
  parser.add_argument('--dry_run', action='store_true')
  parser.add_argument('--tar', nargs='+', type=str)
  parser.add_argument('--notars', action='store_true', help='Must explicitly say there are no tars to be provided')
  parser.add_argument('--skip', type=int, default=0)
  parser.add_argument('--limit', type=int, default=None)
  parser.add_argument('--job-lifetime', default=None, type=int, help='Requested job lifetime in seconds')
  parser.add_argument('--out-lifetime', default=None, type=int,
                      help='Lifetime to give to output datasets -- '
                           'applicable only if a new dataset is being created')
  parser.add_argument('--distance', default=30, type=str, help='Max site--rse distance')
  parser.add_argument('--memory', default=2000, type=str, help='Requested memory')
  parser.add_argument('--nevents', type=int, default=None)
  args = parser.parse_args()

  scope = 'usertests' if args.test else f'fardet-{args.det.lower()}'

  ##Start building up command
  cmd = [
    'justin', 'simple-workflow',
    '--jobscript', args.script,
    '--name', 'atmnu_reco2',
    '--scope', scope,
    '--max-distance', str(args.distance),
    '--rss-mb', str(args.memory),
  ]

  ##Build up list of tars to upload and provide to job
  if args.tar is not None:
    files_and_dir = [i.split(':') for i in args.tar]
    my_file = None
    my_dir = None
    for pair in files_and_dir:
      my_file, my_dir = pair[0], pair[1]
    path = upload_tar(my_file)
    cmd += ['--env', f'{my_dir}={path}'] 

  cmd += ['--mql', f'"files from {build_input(args)}"']
  cmd += build_output(args)

  if args.job_lifetime is not None:
    cmd += ['--wall-seconds', str(args.job_lifetime)]
  if args.nevents is not None:
    cmd += ['--env', f'NEVENTS={args.nevents}']

  if args.out_lifetime is not None:
    cmd += ['--lifetime-days', str(args.out_lifetime)]

  print('Running')
  print(cmd[0], cmd[1])
  for i in range(2, len(cmd), 2):
    print('\t',cmd[i], cmd[i+1])

  if not args.dry_run:
    subprocess.run(' '.join(cmd), shell=True)
