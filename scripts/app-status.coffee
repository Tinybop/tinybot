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
  key = '3539b6983455bff0617d6d447b6d4b2fbf6ca3f2'
  bearer = 'Bearer '+key

  console.log 'key:' + key + ', bearer:' + bearer

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
    console.log 'setting up params for ' + app.app_name
    id = app.app_id
    end =  app.last_sales_date
    start = new Date(end + 'T00:00:00-05:00')
    start.setDate(start.getDate() - 1)
    start = start.yyyymmdd()
    return 'apps/' + id + '/sales?break_down=date+iap&start_date=' + start + '&end_date=' + end

  calcChange = (now, start) ->
    diff = +now - +start
    if diff > 0
      diff = '+' + diff
    return now + ' (' + diff + ')'

  getSales = (app) ->
    async.waterfall [
      (callback) ->
        params = getParams(app)
        getJSON(params).then((salesData) ->
          callback null, app, salesData
        )
      (app, salesData, callback) ->
        app.sales = salesData
        console.log 'sales for ' + app.app_name + '=' + app.sales.sales_list.length
        callback null, app
    ], (err, result) ->
      result

  Date::yyyymmdd = ->
    yyyy = @getFullYear().toString()
    mm = (@getMonth() + 1).toString()
    dd = @getDate().toString()
    yyyy + "-" + ((if mm[1] then mm else "0" + mm[0])) + "-" + ((if dd[1] then dd else "0" + dd[0]))

  # robot.respond /app status/i, (msg) ->
  robot.hear /a/i, (msg) ->
    console.log 'heard'

    unless key?
      msg.send "Please specify your App Annie API key in APP_ANNIE_KEY"
      return
    msg.send "Checking now…"

    async.waterfall [

      (callback) ->
        # Get the Account Connection App List
        # http://support.appannie.com/entries/23215137-2-Account-Connection-App-List
        getJSON('apps').then((appData) ->
          console.log 'appData recieved'
          return callback null, appData
        )
      (appData, callback) ->
        # Get App Sales data for each app in the app_list and attach it to app
        # http://support.appannie.com/entries/23215097-3-App-Sales
        async.each appData.app_list, ((app, callback) ->
          console.log "Processing app " + app.app_name
          params = getParams(app)
          getJSON(params).then((salesData) ->
            app.sales = salesData
            callback()
            return app
          )
          return app
        ), (err) ->
          if err
            console.log "An app failed to process"
          else
            console.log "All apps have been processed successfully"
            return callback null, appData
      (appData, callback) ->
        output = []

        date = new Date(appData.app_list[0].last_sales_date + 'T00:00:00-05:00')
        options = {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        }
        output.push date.toLocaleDateString('en-US', options)

        for app in appData.app_list
          output.push '============================='
          output.push ' '
          output.push app.app_name
          output.push '    Sales: ' + calcChange(
            app.sales.sales_list[0].units.app.downloads,
            app.sales.sales_list[1].units.app.downloads
          )
          output.push '  Updates: ' + calcChange(
            app.sales.sales_list[0].units.app.updates,
            app.sales.sales_list[1].units.app.updates
          )
          if app.sales.sales_list[0].units.iap and app.sales.sales_list[0].units.iap.sales > 0
            output.push '      IAP: ' + calcChange(
              app.sales.sales_list[0].units.iap.updates,
              app.sales.sales_list[1].units.iap.updates
            )
          output.push ' '

        output = output.reduce (x, y) -> x + '\n' + y

        callback null, output
    ], (err, result) ->
      msg.send(result)
