# Description:
#   Fetches app status info from App Annie
#
# Dependencies:
#   "rsvp": "^3.0.13"
#   "async": "^0.9.0"
#
# Configuration:
#   APP_ANNIE_KEY
#
# Commands:
#   tinybot app status
#
# Author:
#   Josh Stewart
#
rsvp = require 'rsvp'
async = require 'async'

module.exports = (robot) ->

  key = process.env.APP_ANNIE_KEY
  bearer = 'Bearer ' + key

  getJSON = (params) ->
    promise = new rsvp.Promise((resolve, reject) ->
      url = 'https://api.appannie.com/v1/accounts/157063/' + params
      robot.http(url)
        .header('Authorization', bearer)
        .get() (err, res, body) ->
          resolve JSON.parse(body)
    )
    promise

  getParams = (app) ->
    id = app.app_id
    end =  app.last_sales_date
    start = new Date(end + 'T00:00:00-05:00')
    start.setDate(start.getDate() - 1)
    start = start.yyyymmdd()
    'apps/' + id + '/sales?break_down=date+iap&start_date=' + start + '&end_date=' + end

  calcChange = (now, start) ->
    diff = +now - +start
    diff = '+' + diff  if diff > 0
    now + ' (' + diff + ')'

  # TODO: clean up date formatter
  Date::yyyymmdd = ->
    yyyy = @getFullYear().toString()
    mm = (@getMonth() + 1).toString()
    dd = @getDate().toString()
    yyyy + '-' + ((if mm[1] then mm else '0' + mm[0])) + '-' + ((if dd[1] then dd else '0' + dd[0]))

  # TODO: move get app data function out here

  # TODO: if robot.brain.get('appData')
    # test if it is fresh
  # else
    # get data

  # TODO: add robot brain clearing command

  robot.respond /app status/i, (msg) ->

    unless key?
      msg.send 'Please specify your App Annie API key in APP_ANNIE_KEY'
      return
    msg.send 'Checking now…'

    async.waterfall [
      (callback) ->
        # Get the Account Connection App List
        # http://support.appannie.com/entries/23215137-2-Account-Connection-App-List
        getJSON('apps').then((appData) ->
          callback null, appData
        )
      (appData, callback) ->
        # Get App Sales data for each app in the app_list and attach it to app
        # http://support.appannie.com/entries/23215097-3-App-Sales
        async.each appData.app_list, ((app, callback) ->
          params = getParams(app)
          getJSON(params).then (salesData) ->
            app.sales = salesData
            callback()
            app
          app
        ), (err) ->
          if err
            msg.send 'An app failed to process'
          else
            # TODO: save app data in brain for later
            callback null, appData
      (appData, callback) ->
        output = ['/code ']
        date = new Date(appData.app_list[0].last_sales_date + 'T00:00:00-05:00')
        options =
          weekday: 'long'
          year: 'numeric'
          month: 'long'
          day: 'numeric'

        output.push date.toLocaleDateString('en-US', options)
        for app in appData.app_list
          output.push '============================='
          output.push ' '
          app.app_name = 'Tinybop Explorers 1 & 2' if app.app_name is 'n/a' and app.app_id is '917509967'
          output.push app.app_name
          output.push '    Sales: ' + calcChange(
            app.sales.sales_list[0].units.app.downloads,
            app.sales.sales_list[1].units.app.downloads
          )
          output.push '  Updates: ' + calcChange(
            app.sales.sales_list[0].units.app.updates,
            app.sales.sales_list[1].units.app.updates
          )
          if app.sales.iap_sales.length > 0
            output.push '      IAP: ' + calcChange(
              app.sales.sales_list[0].units.iap.sales,
              app.sales.sales_list[1].units.iap.sales
            )
          output.push ' '
        output = output.reduce (x, y) ->
          x + '\n' + y
        callback null, output
    ], (err, result) ->
      msg.send(result)
