import os
import subprocess
import sys

# List of environment variables to unset due to the socks proxy
variables_to_unset = [
    'ALL_PROXY',
    'all_proxy',
    'HTTP_PROXY',
    'http_proxy',
    'HTTPS_PROXY',
    'https_proxy',
]

# Unset specific environment variables
for var in variables_to_unset:
    os.environ.pop(var, None)

command = ["ngrok", "http", "--domain=equal-magnetic-pheasant.ngrok-free.app", "8000"]
try:
    # Start the ngrok process
    result = subprocess.Popen(command, stdout=sys.stdout, stderr=sys.stderr)

    # Wait for the process to complete
    result.wait()
except KeyboardInterrupt:
    # Handle the keyboard interrupt and terminate the subprocess
    print("\nTerminating ngrok process...")
    result.terminate()
    result.wait()
    print("ngrok process has been terminated.")