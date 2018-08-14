import csv
import subprocess

from jadi import component
from aj.api.http import url, HttpPlugin
from aj.api.endpoint import endpoint, EndpointError
from aj.plugins.lm_common.api import CSVSpaceStripper
from aj.plugins.lm_common.api import lm_backup_file
from aj.auth import authorize



@component(HttpPlugin)
class Handler(HttpPlugin):
    def __init__(self, context):
        self.context = context

    @url(r'/api/lm/devices')
    @authorize('lm:devices')
    @endpoint(api=True)
    def handle_api_devices(self, http_context):
        path = '/etc/linuxmuster/sophomorix/default-school/devices.csv'
        fieldnames = [
            'room',
            'hostname',
            'group',
            'mac',
            'ip',
            'officeKey',
            'windowsKey',
            'dhcpOptions',
            'sophomorixRole',
            'lmnReserved10',
            'pxeFlag',
            'lmnReserved12',
            'lmnReserved13',
            'lmnReserved14',
            'sophomorixComment',
            'options',
        ]
        if http_context.method == 'GET':
            return list(
                csv.DictReader(CSVSpaceStripper(open(path)), delimiter=';', fieldnames=fieldnames)
            )
        if http_context.method == 'POST':
            data = http_context.json_body()
            for item in data:
                item.pop('_isNew', None)
                item.pop('null', None)
            lm_backup_file(path)
            with open(path, 'w') as f:
                csv.DictWriter(f, delimiter=';', fieldnames=fieldnames).writerows(data)

    @url(r'/api/lm/devices/import')
    @authorize('lm:devices:import')
    @endpoint(api=True)
    def handle_api_devices_import(self, http_context):
        try:
            subprocess.check_call('linuxmuster-import-devices > /tmp/import_devices.log', shell=True)
        except Exception as e:
            raise EndpointError(None, message=str(e))

    @url(r'/api/lm/leases')
    @authorize('lm:leases')
    @endpoint(api=True)
    def handle_api_leasees(self, http_context):
        from isc_dhcp_leases import Lease, IscDhcpLeases
        import socket 

        leases   = IscDhcpLeases('/var/lib/dhcp/dhcpd.leases')
        dhcpList = leases.get()
        active   = leases.get_current()
        dhcpList.sort(key=lambda x: x.ip)
        items = sorted(dhcpList, key=lambda item: socket.inet_aton(item.ip))
        
        result = []
        
        for l in items:
                registered = False
                active = False
                with open("/etc/linuxmuster/sophomorix/default-school/devices.csv", "r") as f:
                        contents = f.read().split()
                if l.ethernet in contents:
                        registered = True
                if l.active:
                        active = True
                result.append({'IP':l.ip, 'MAC':l.ethernet, 'registered':registered, 'active':active})
        if http_context.method == 'GET':
            return result
