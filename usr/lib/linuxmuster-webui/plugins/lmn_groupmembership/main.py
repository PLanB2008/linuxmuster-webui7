from jadi import component
from aj.plugins.core.api.sidebar import SidebarItemProvider
from aj.auth import PermissionProvider


@component(SidebarItemProvider)
class ItemProvider(SidebarItemProvider):
    def __init__(self, context):
        self.context = context

    def provide(self):
        return [
            {
                'attach': 'category:class',
                'name': _('Enroll'),
                'icon': 'edit',
                'url': '/view/lmn/groupmembership',
                'children': [],
                'weight': 25,

            },
        ]


@component(PermissionProvider)
class Permissions (PermissionProvider):
    def provide(self):
        return [
            {
                'id': 'lmn:groupmembership',
                'name': _('Edit Groupmemberships'),
                'default': False,
            },
            {
                'id': 'lmn:groupmemberships:write',
                'name': _('Edit Groups'),
                'default': False,
            },
        ]
