Meteor.methods
  createUserWithEmail: (emailAddress) ->
    user = { email: emailAddress }
    domain = GlobalSettings.getSetting 'restrictedDomain'
    if domain
      user.email = "#{emailAddress}@#{domain}"
      user.username = emailAddress
    userId = Accounts.createUser(user)
    Accounts.sendEnrollmentEmail(userId)

Meteor.startup ->
  if Meteor.settings.teams?
    Meteor.settings.teams.forEach (team) ->
      unless Teams.findOne(name: team.name)?
        console.log("Adding team #{team.name}")
        Teams.insert(name: team.name)

  if Meteor.settings.checkins?
    Meteor.settings.checkins.forEach (checkinData) ->
      team = Teams.findOne(name: checkinData.teamName)
      unless Checkins.findOne(day: checkinData.day, teamId: team._id, description: checkinData.description)?
        console.log("Adding checkin for team #{team.name} on #{new Date(checkinData.day).toLocaleDateString()}")
        Checkins.insert
          teamId: team._id
          description: checkinData.description
          day: checkinData.day
          createdDate: (new Date()).toISOString()

  if Meteor.settings.globalSettings?
    domain = Meteor.settings.globalSettings.restrictedDomain
    if domain?
      console.log("Adding global setting: restrictedDomain = #{domain}")
      if domain
        domain = domain.trim()
      GlobalSettings.setSetting 'restrictedDomain', domain

    usersEnabled = Meteor.settings.globalSettings.usersEnabled and domain and process.env.MAIL_URL
    console.log("Adding global setting: usersEnabled = #{usersEnabled}")
    GlobalSettings.setSetting 'usersEnabled', usersEnabled