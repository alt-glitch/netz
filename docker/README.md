## Usage

`cat <IP-LIST> | xargs -I@ docker run -e PORT_TO_SCAN='' -e SUBNET_TO_SCAN=@ TASK_DEFINITION='@' -v /path/to/results/:/opt/out --network=host netz-2`

