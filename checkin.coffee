@Teams = new Meteor.Collection('players')
@Checkins = new Meteor.Collection('checkins')
@GlobalSettings = new Meteor.Collection('global_settings')

##
## Checkins helper functions
##

Checkins.addOrUpdate = (teamId, userId, description) ->
  latest = Checkins.latest teamId
  createdDate = new Date()
  day = new Date(createdDate.getFullYear(), createdDate.getMonth(), createdDate.getDate()).toISOString()
  if not latest or day isnt latest.day
    Checkins.insert
      teamId: teamId
      description: description
      day: day
      createdDate: createdDate.toISOString()
      user: userId
  else
    Checkins.update { _id: latest._id }, { $set: { description: description, user: userId }}

Checkins.latest = (teamId) -> Checkins.findOne(
  {teamId: teamId},
  {sort: [
    ['day', 'desc']
    ['createdDate', 'desc']]})

##
## GlobalSettings helper functions
##

GlobalSettings.settingExists = (settingName) ->
  GlobalSettings.findOne({ name: settingName })?

GlobalSettings.getSetting = (settingName) ->
  setting = GlobalSettings.findOne { name: settingName }
  if setting? and setting.value? then setting.value else null

GlobalSettings.setSetting = (settingName, settingValue) ->
  setting = { name: settingName, value: settingValue }
  if GlobalSettings.settingExists settingName
    GlobalSettings.update { name: settingName }, setting
  else
    GlobalSettings.insert setting


@Time =
  occursToday: (date) ->
    todayStart = (new Date()).setHours(0,0,0,0)
    todayStart <= date
  occurredYesterday: (date) ->
    todayStart = (new Date()).setHours(0,0,0,0)
    yesterdayStart = todayStart - 86400000
    yesterdayStart <= date and todayStart > date
  occurredThisWeek: (date) ->
    todayStart = (new Date()).setHours(0,0,0,0)
    yesterdayStart = todayStart - 604800000
    yesterdayStart <= date and todayStart > date
  minsAgo: (date) ->
    (new Date() - date)/60000
  timeAgoString: (date) ->
    diffMins = Time.minsAgo(date)
    if diffMins < 0
      "Sometime in the future"
    else if Time.occursToday(date)
      "Today"
    else if Time.occurredYesterday(date)
      "Yesterday"
    else if diffMins < 44640
      dayNum = Math.floor(diffMins/1440)
      "#{dayNum} days ago"
    else
      monthNum = Math.floor(diffMins/44640)
      "#{monthNum} month#{if monthNum > 1 then 's' else ''} ago"


class @CurrentDate
  instance = null
  interval = null
  date = null
  dateDep = new Deps.Dependency()
  update = ->
    date = new Date()
    dateDep.changed()
  setInterval = -> interval = Meteor.setInterval(update, 60000)
  clearInterval = -> Meteor.clearInterval(interval)
  class PrivateDate
    constructor: ->
      update()
      setInterval()
    depend: -> dateDep.depend()
    getDate: -> date
  @get: ->
    instance ?= new PrivateDate()
