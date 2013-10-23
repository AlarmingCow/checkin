Router.configure
  layout: 'layout'
  renderTemplates: { nav: { to: 'nav' }}

Router.map ->
  this.route 'main', { path: '/' }
  this.route 'observatory', { path: '/observatory' }
  this.route 'enroll-account', {
    path: '/enroll-account/:token',
    controller: 'VerifyEmailController',
  }

class @MainController extends RouteController
  template: 'main'

class @ObservatoryController extends RouteController
  template: 'observatory'

class @VerifyEmailController extends MainController
  run: ->
    this.render()
    token = this.params.token
    Accounts.verifyEmail token
    Session.set 'token', token
    Meteor.defer -> $('#verify-email-modal').modal()
  hide: ->
    $('#verify-email-modal').modal('hide')


Template.nav.usersEnabled = -> GlobalSettings.getSetting 'usersEnabled'
Template.nav.events =
  'click #log-out-btn': ->
    Meteor.logout (error) -> console.log(error)


Template.main.teams = -> Teams.find({}, {sort: [['name', 'asc']]})
Template.main.usersEnabled = -> GlobalSettings.getSetting 'usersEnabled'
Template.main.teamColumns = ->
  teams = Teams.find({}, {sort: [['name', 'asc']]}).fetch()
  numColumns = 4
  chunkSize = Math.ceil teams.length/numColumns
  teamColumns = []
  for i in [0...numColumns]
    teamColumns.push teams[chunkSize*i ... chunkSize*(i+1)]
  teamColumns
Template.main.checkins = () -> Checkins.find()
Template.main.showDays = -> Session.get('showDays')
Template.main.restrictedDomain = -> GlobalSettings.getSetting 'restrictedDomain'
Template.main.days = () ->
  days = Template.main.checkins().map (checkin) -> checkin.day
  _.uniq(days).sort().reverse().map (day) -> new Date(day)
Template.main.columnWidth = -> 100 / (Template.main.teams().count())
Template.main.events =
  'click #show-days-yes': ->
    Session.set('showDays', true)
  'click #show-days-no': ->
    Session.set('showDays', false)
  'click #create-user': ->
    emailAddress = $('#create-user-email').val().trim()
    Meteor.call('createUserWithEmail', emailAddress)
  'click #create-password': ->
    Accounts.resetPassword Session.get('token'), $('#password-input').val()
    Router.go 'main'
  'click #sign-in-button': ->
    emailAddress = $('#sign-in-email').val()
    password = $('#sign-in-password').val()
    if GlobalSettings.getSetting 'restrictedDomain'
      Meteor.loginWithPassword { username: emailAddress }, password
    else
      Meteor.loginWithPassword {email: emailAddress}, password


Template.teamHeader.edit = -> Session.equals('adding', @_id)
Template.teamHeader.alreadyCheckedIn = ->
  latest = Checkins.latest(@_id)
  latest? and Time.occursToday(new Date(latest.createdDate))
Template.teamHeader.latestCheckin = ->
  Checkins.latest(@_id)
Template.teamHeader.events =
  'click .add-checkin': ->
    Session.set('adding', @_id)
  'click .lazy-button-confirm': -> Checkins.addOrUpdate @_id, Meteor.userId(), Checkins.latest(@_id).description
  'click .delete-checkin-confirm': -> Checkins.remove { _id: Checkins.latest(@_id)._id }
Template.teamHeader.timeLabel = ->
  CurrentDate.get().depend()
  checkin = Checkins.latest(@_id)
  Time.timeAgoString((new Date(checkin.day))) if checkin
Template.teamHeader.timeLabelClass = ->
  CurrentDate.get().depend()
  checkin = Checkins.latest(@_id)
  if checkin
    if Time.occursToday((new Date(checkin.day)))
      "label-success"
    else if Time.occurredThisWeek((new Date(checkin.day)))
      "label-warning"


Template.day.dateString = -> @toLocaleDateString()
Template.day.teamDays = -> Template.main.teams()
    .map (team) =>
      team: team
      day: @


Template.teamDay.checkins = -> Checkins.find(
  {
    teamId: @team._id
    day: @day.toISOString()
  },
  {
    sort: [['createdDate', 'desc']],
    transform: (checkin) ->
      checkin.display = Emoji.convert(checkin.description) if checkin.description
      checkin
  })


Template.teamLatest.checkin = ->
  checkin = Checkins.latest(@_id)
  if checkin?
    checkin.display = Emoji.convert(checkin.description)
  checkin
Template.teamLatest.edit = -> Session.equals('adding', @_id)
Template.teamLatest.preview = -> Session.get('preview')
Template.teamLatest.events =
  'click #save-new-checkin': ->
    description = $('#text').val()
    Checkins.addOrUpdate @_id, Meteor.userId(), description
    $('#text').val('')
    Session.set('preview', '')
    Session.set('adding', null)
  'click #cancel-new-checkin': ->
    Session.set('preview', '')
    Session.set('adding', null)
  'keyup #text': -> Session.set('preview', Emoji.convert($('#text').val()))
