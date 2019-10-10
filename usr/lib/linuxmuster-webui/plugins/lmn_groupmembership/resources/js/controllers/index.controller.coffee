angular.module('lmn.groupmembership').config ($routeProvider) ->
    $routeProvider.when '/view/lmn/groupmembership',
        controller: 'LMNGroupMembershipController'
        templateUrl: '/lmn_groupmembership:resources/partial/index.html'

angular.module('lmn.groupmembership').controller 'LMNGroupDetailsController', ($scope, $route, $uibModal, $uibModalInstance, $http, gettext, notify, messagebox, pageTitle, groupType, groupName) ->

        $scope.editGroupMembers = (groupName, groupDetails, admins) ->
            $uibModal.open(
                templateUrl: '/lmn_groupmembership:resources/partial/editMembers.modal.html'
                controller:  'LMNGroupEditController'
                size: 'lg'
                resolve:
                   groupName: () -> groupName
                   groupDetails: () -> groupDetails
                   admins: () -> admins
            ).result.then (result)->
                if result.response is 'refresh'
                    $scope.getGroupDetails ([groupType, groupName])

        $scope.showAdminDetails = true
        $scope.showMemberDetails = true
        $scope.changeState = false

        $scope.hidetext = gettext("Hide")
        $scope.showtext = gettext("Show")

        $scope.changeJoin = (group, type) ->
            $scope.changeState = true
            option = if $scope.joinable then '--join' else '--nojoin'
            $http.post('/api/lmn/changeGroup', {option: option, group: group, type: type}).then (resp) ->
                if resp['data'][0] == 'ERROR'
                    notify.error (resp['data'][1])
                if resp['data'][0] == 'LOG'
                    notify.success gettext(resp['data'][1])
                $scope.changeState = false

        $scope.changeHide = (group, type) ->
            $scope.changeState = true
            option = if $scope.hidden then '--hide' else '--nohide'
            $http.post('/api/lmn/changeGroup', {option: option, group: group, type: type}).then (resp) ->
                if resp['data'][0] == 'ERROR'
                    notify.error (resp['data'][1])
                if resp['data'][0] == 'LOG'
                    notify.success gettext(resp['data'][1])
                $scope.changeState = false

        $scope.killProject = (project) ->
             messagebox.show(text: "Do you really want to delete '#{project}'? This can't be undone!", positive: 'Delete', negative: 'Cancel').then () ->
                msg = messagebox.show(progress: true)
                $http.post('/api/lmn/groupmembership', {action: 'kill-project', username:$scope.identity.user, project: project, profil: $scope.identity.profile}).then (resp) ->
                    if resp['data'][0] == 'ERROR'
                        notify.error (resp['data'][1])
                    if resp['data'][0] == 'LOG'
                        notify.success gettext(resp['data'][1])
                        $uibModalInstance.close(response: 'refresh')
                .finally () ->
                    msg.close()

        $scope.nevertext = gettext('Never')

        $scope.formatDate = (date) ->
            if (date == "19700101000000.0Z")
                return $scope.nevertext
            else if (date == undefined)
                return "undefined"
            else
                # Sophomorix date format is yyyyMMddhhmmss.0Z
                year  = date.slice(0,4)
                month = +date.slice(4,6) - 1 # Month start at 0
                day   = date.slice(6,8)
                hour  = date.slice(8,10)
                min   = date.slice(10,12)
                sec   = date.slice(12,14)
                return new Date(year, month, day, hour, min, sec)

        $scope.filterDNLogin = (dn) ->
            if dn.indexOf('=') != -1
                return dn.split(',')[0].split('=')[1]
            else
                return dn

        $scope.getGroupDetails = (group) ->
            groupType = group[0]
            groupName = group[1]
            $http.post('/api/lmn/groupmembership/details', {action: 'get-specified', groupType: groupType, groupName: groupName}).then (resp) ->
                $scope.groupName    = groupName
                $scope.groupDetails = resp.data['GROUP'][groupName]
                $scope.adminList = resp.data['GROUP'][groupName]['sophomorixAdmins']
                $scope.groupmemberlist = resp.data['GROUP'][groupName]['sophomorixMemberGroups']
                $scope.groupadminlist = resp.data['GROUP'][groupName]['sophomorixAdminGroups']

                $scope.members = []
                for name,member of resp.data['MEMBERS'][groupName]
                    if member.sn != "null" # group member 
                        $scope.members.push({'sn':member.sn, 'givenName':member.givenName, 'sophomorixAdminClass':member.sophomorixAdminClass})

                $scope.admins = []
                for admin in $scope.adminList
                    member = resp.data['MEMBERS'][groupName][admin]
                    $scope.admins.push({'sn':member.sn, 'givenName':member.givenName, 'sophomorixAdminClass':member.sophomorixAdminClass})

                $scope.joinable = resp.data['GROUP'][groupName]['sophomorixJoinable'] == 'TRUE'
                $scope.hidden = resp.data['GROUP'][groupName]['sophomorixHidden'] == 'TRUE'
                
                # Admin or admin of the project can edit members of a project
                # Only admins can change hide and join option for a class
                if $scope.identity.isAdmin
                    $scope.editMembersButton = true
                else if (groupType == "project") and ($scope.adminList.indexOf($scope.identity.user) != -1 or $scope.groupadminlist.indexOf($scope.identity.profile.sophomorixAdminClass) != -1)
                    $scope.editMembersButton = true
                else
                    $scope.editMembersButton = false

        $scope.groupType = groupType
        $scope.getGroupDetails ([groupType, groupName])
        $scope.close = () ->
            $uibModalInstance.dismiss()

angular.module('lmn.groupmembership').controller 'LMNGroupEditController', ($scope, $route, $uibModal, $uibModalInstance, $http, gettext, notify, messagebox, pageTitle, groupName, groupDetails, admins) ->
        $scope.sorts = [
            {
                name: gettext('Given name')
                id: 'givenName'
                fx: (x) -> x.givenName
            }
            {
                name: gettext('Name')
                id: 'sn'
                fx: (x) -> x.sn
            }
            {
                name: gettext('Membership')
                id: 'membership'
                fx: (x) -> x.membership
            }
            #{
            #    name: gettext('Class')
            #    fx: (x) -> x.sophomorixAdminClass
            #}
        ]
        $scope.sort = $scope.sorts[1]
        $scope.groupName = groupName
        $scope.admins = admins
        $scope.sortReverse = false
        groupDN = groupDetails['DN']
        
        $scope.addgroupmembertext = gettext('Add/remove as member group')
        $scope.addgroupadmintext = gettext('Add/remove as admin group')

        $scope.admingroups = groupDetails['sophomorixAdminGroups']
        $scope.membergroups = groupDetails['sophomorixMemberGroups']

        $scope.checkInverse = (sort ,currentSort) ->
            if sort == currentSort
                $scope.sortReverse = !$scope.sortReverse
            else
                $scope.sortReverse = false

        $scope.updateAdminList = (teacher) ->
            idx = $scope.admins.indexOf(teacher.sAMAccountName)
            if idx >= 0
                $scope.admins.splice(idx, 1)
            else
                $scope.admins.push(teacher.sAMAccountName)

        $scope.updateGroupAdminList = (cl) ->
            idx = $scope.admingroups.indexOf(cl)
            if idx >= 0
                $scope.admingroups.splice(idx, 1)
            else
                $scope.admingroups.push(cl)
                # If group teachers, remove each teacher from adminlist
                if cl == 'teachers'
                    newadmins = []
                    for admin in $scope.admins
                        idx = $scope.teacherlist.indexOf(admin)
                        if idx < 0
                            newadmins.push(admin)
                    $scope.admins = newadmins
                    console.log($scope.admins, $scope.teacherlist)
                            
        $scope.updateGroupMemberList = (cl) ->
            idx = $scope.membergroups.indexOf(cl)
            console.log(cl)
            if idx >= 0
                $scope.membergroups.splice(idx, 1)
            else
                $scope.membergroups.push(cl)
                for student in $scope.students
                    if student['sophomorixAdminClass'] == cl
                        student['membership'] = false
                if cl == 'teachers'
                    for teacher in $scope.teachers
                        teacher['membership'] = false 

        $scope.setMembers = (students, teachers) ->
            msg = messagebox.show(progress: true)
            members = students.concat(teachers)
            $http.post('/api/lmn/groupmembership/details', 
                        {
                            action: 'set-members', 
                            username:$scope.identity.user, 
                            members: members, 
                            groupName: groupName, 
                            admins: $scope.admins, 
                            membergroups: $scope.membergroups, 
                            admingroups: $scope.admingroups
                        }
            ).then (resp) ->
                if resp['data'][0] == 'ERROR'
                    notify.error (resp['data'][1])
                if resp['data'][0] == 'LOG'
                    notify.success gettext(resp['data'][1])
                    $uibModalInstance.close(response: 'refresh')
                    #$scope.resetClass()
            .finally () ->
                msg.close()

        $http.post('/api/lm/sophomorixUsers/students', {action: 'get-all'}).then (resp) ->
            students = resp.data
            $scope.students = students
            classes = []
            for student in students
                if student['sophomorixAdminClass'] not in classes
                    classes.push student['sophomorixAdminClass']
                if groupDN in student['memberOf']
                    student['membership'] = true
                else
                    student['membership'] = false
            $scope.classes = classes
            ## TODO : add class ?
            ## TODO : add other project members ?
        $http.post('/api/lm/sophomorixUsers/teachers', {action: 'get-list'}).then (resp) ->
            $scope.teachers = resp.data
            $scope.teacherlist = []
            for teacher in $scope.teachers
                teacher['membership'] = groupDN in teacher['memberOf']
                $scope.teacherlist.push(teacher['sAMAccountName'])

        $scope.close = () ->
            $uibModalInstance.dismiss()

angular.module('lmn.groupmembership').controller 'LMNGroupMembershipController', ($scope, $http, $uibModal, gettext, notify, pageTitle, messagebox, validation) ->
    pageTitle.set(gettext('Enrolle'))
    $scope.types = {
        schoolclass:
            typename: gettext('Schoolclass')
            name: gettext('Groupname')
            checkbox: true
            type: 'schoolclass'

        printergroup:
            typename: gettext('Printer')
            checkbox: true
            type: 'printergroup'

        project:
            typename: gettext('Projects')
            checkbox: true
            type: 'project'
    }

    $scope.sorts = [
        {
            name: gettext('Groupname')
            fx: (x) -> x.groupname
        }
        {
            name: gettext('Membership')
            fx: (x) -> x.membership
        }
    ]
    $scope.sort = $scope.sorts[0]
    $scope.sortReverse= false
    $scope.paging =
       page: 1
       pageSize: 20

    $scope.isActive = (group) ->
        if  group.type is 'printergroup'
            if $scope.types.printergroup.checkbox is true
                return true
        if  group.type is 'schoolclass'
            if $scope.types.schoolclass.checkbox is true
                return true
        if  group.type is 'project'
            if $scope.types.schoolclass.checkbox is true
                return true
        return false

    $scope.checkInverse = (sort ,currentSort) ->
        if sort == currentSort
            $scope.sortReverse = !$scope.sortReverse
        else
            $scope.sortReverse = false

    $scope.resetClass = () ->
       # reset html class back (remove changed) so its not highlighted anymore
       result = document.getElementsByClassName("changed")
       while result.length
          result[0].className = result[0].className.replace( /(?:^|\s)changed(?!\S)/g , '' )
       # reset $scope.group attribute back not not changed so an additional enroll will not set these groups again
       for group in $scope.groups
           group['changed']= false
       return


    $scope.groupChanged = (item) ->
        for group in $scope.groups
            if group['groupname'] == item
                group['changed'] = !group['changed']

    $scope.filterGroupType = (val) ->
        return (dict) ->
            dict['type'] == val

    $scope.getGroups = (username) ->
        $http.post('/api/lmn/groupmembership', {action: 'list-groups', username: username, profil: $scope.identity.profile}).then (resp) ->
            $scope.groups = resp.data[0]
            $scope.identity.isAdmin = resp.data[1]

            $scope.classes = $scope.groups.filter($scope.filterGroupType('schoolclass'))
            $scope.projects = $scope.groups.filter($scope.filterGroupType('project'))
            ## Printers yet DEPRECATED ?
            $scope.printers = $scope.groups.filter($scope.filterGroupType('printergroup'))
            console.log($scope.classes)

    $scope.setGroups = (groups) ->
        $http.post('/api/lmn/groupmembership', {action: 'set-groups', username:$scope.identity.user, groups: groups, profil: $scope.identity.profile}).then (resp) ->
            if resp['data'][0] == 'ERROR'
                notify.error (resp['data'][1])
            if resp['data'][0] == 'LOG'
                notify.success gettext(resp['data'][1])
                $scope.resetClass()
            if resp.data == 0
                notify.success gettext("Nothing changed")

    $scope.createProject = () ->
        messagebox.prompt(gettext('Project Name'), '').then (msg) ->
            if not msg.value
                return
            test = validation.isValidProjectName(msg.value)
            if test != true
                notify.error gettext(test)
                return
            $http.post('/api/lmn/groupmembership', {action: 'create-project', username:$scope.identity.user, project: msg.value, profil: $scope.identity.profile}).then (resp) ->
                notify.success gettext('Project Created')
                $scope.getGroups ($scope.identity.user)

    $scope.showGroupDetails = (index, groupType, groupName) ->
        $uibModal.open(
            templateUrl: '/lmn_groupmembership:resources/partial/groupDetails.modal.html'
            controller:  'LMNGroupDetailsController'
            size: 'lg'
            resolve:
               groupType: () -> groupType
               groupName: () -> groupName
        ).result.then (result)->
            if result.response is 'refresh'
                $scope.getGroups ($scope.identity.user)

    $scope.projectIsJoinable = (project) ->
        return project['joinable'] == 'TRUE' or project.admin or $scope.identity.isAdmin or $scope.identity.profile.memberOf.indexOf(project['DN']) > -1

    $scope.$watch 'identity.user', ->
        if $scope.identity.user is undefined
           return
        if $scope.identity.user is null
           return
        if $scope.identity.user is 'root'
           # $scope.identity.user = 'hulk'
           return
        $scope.getGroups($scope.identity.user)
        return
