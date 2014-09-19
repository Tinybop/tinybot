# Description:
#   Fetches app status info from App Annie
#
# Dependencies:
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


module.exports = (robot) ->
  # robot.respond /app status/i, (msg) ->
  robot.hear /a/i, (msg) ->

    console.log 'heard'

    # ----------
    # Helpers
    # ----------

    # Format a date as YYYY-MM-DD
    Date::formatted = ->
      yyyy = @getFullYear().toString()
      mm = (@getMonth() + 1).toString()
      dd = @getDate().toString()
      yyyy + '-' + ((if mm[1] then mm else "0" + mm[0])) + '-' + ((if dd[1] then dd else "0" + dd[0]))

    # ----------
    # Variables
    # ----------

    # key = process.env.APP_ANNIE_KEY
    key = '3539b6983455bff0617d6d447b6d4b2fbf6ca3f2'

    today = new Date()

    yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    yesterday = yesterday.formatted()

    daybefore = new Date()
    daybefore.setDate(daybefore.getDate() - 2)
    daybefore = daybefore.formatted()

    bearer = 'Bearer '+key

    console.log 'key:' + key + ', today:' + today + ', yesterday:' + yesterday + ', daybefore:' + daybefore + ', bearer:' + bearer


    # ----------
    # Initialize
    # ----------

    unless key?
      msg.send "Please specify your App Annie API key in APP_ANNIE_KEY"
      return

    msg.send "Checking now…"

    getAppList = () ->

      console.log 'getAppList called'

      robot.http('https://api.appannie.com/v1/accounts/157063/apps?page_index=0')
        .header('Authorization', bearer)
        .get() (err, res, body) ->
          # err & response status checking code here
          # console.log 'err:' + err + ', res:' + res + ', body:' + body

          data = null

          try
            data = JSON.parse(body)
          catch error
           msg.send 'Ran into an error parsing JSON :('
           return

          appList = data.app_list
          console.log 'appList: ' + appList.length + ' apps'

          # getAppSales(app) for app in appList

          extend = exports.extend = (object, properties) ->
            for key, val of properties
              object[key] = val
            object

          apps = for app in appList
            # getAppSales(app)
            id = app.app_id
            robot.http('https://api.appannie.com/v1/accounts/157063/apps/'+id+'/sales?break_down=date+iap&start_date='+daybefore+'&end_date='+yesterday)
              .header('Authorization', bearer)
              .get() (err, res, body) ->
                # err & response status checking code here
                # console.log 'err:' + err + ', res:' + res + ', body:' + body

                data = null

                try
                  data = JSON.parse(body)
                  app['sales'] = data.sales_list
                  console.log 'app.sales[0]' + app.sales[0]
                  return app
                catch error
                  msg.send 'Ran into an error parsing JSON :('
                  return



          console.log 'apps:' + apps
          debugger

          dataFormatter(apps)

    dataFormatter = (data) ->
      console.log 'data: ' + data
      debugger

    getAppSales = (app) ->

      id = app.app_id

      console.log 'getAppSales called with id:' + id
      debugger

      app['sales'] = robot.http('https://api.appannie.com/v1/accounts/157063/apps/'+id+'/sales?break_down=date+iap&start_date='+daybefore+'&end_date='+yesterday)
        .header('Authorization', bearer)
        .get() (err, res, body) ->
          # err & response status checking code here
          # console.log 'err:' + err + ', res:' + res + ', body:' + body

          data = null

          try
            data = JSON.parse(body)
          catch error
           msg.send 'Ran into an error parsing JSON :('
           return

          salesList = data.sales_list
          console.log 'salesList' + salesList
          debugger
          return salesList

      debugger

    getAppList()



    # getData = (params, callback) ->
    #   console.log 'getData called'
    #   console.log params
    #   console.log callback
    #
    #   url =
    #   # https://api.appannie.com/v1/accounts/157063/sales?break_down=application+date&start_date=#{daybefore}&end_date=#{yesterday}
    #   robot.http(url)
    #     .header('Authorization', bearer)
    #     .get() (err, res, body) ->
    #       # err & response status checking code here
    #       console.log 'err:' + err + ', res:' + res + ', body:' + body
    #
    #       data = null
    #
    #       try
    #         data = JSON.parse(body)
    #         console.log 'data.app_list returning: ' + data.app_list
    #         return data
    #       catch error
    #        msg.send 'Ran into an error parsing JSON :('
    #        return
    #
    #       console.log 'data is coming' + data
    #       return data


    # getData('https://api.appannie.com/v1/accounts/157063/sales?break_down=application+date&start_date=#{daybefore}&end_date=#{yesterday}')


    # Get app list
    # appList = {}
    # appList = getData('https://api.appannie.com/v1/accounts/157063/apps?page_index=0')
    #
    #
    # setTimeout () ->
    #   appList = appList
    #   msg.send 'appList' + appList
    # , 2000

    # appListCallback = () ->
    #   console.log 'appList: ' + appList


    # appList = data.app_list
      # https://api.appannie.com/v1/accounts/157063/apps?page_index=0

    # for each app.app_id in applist, get app sales for yesterday and the daybefore

    # prepare data for output

# September 17, 2014
# =============================
#
# Plants by Tinybop
#     Sales: 97 (+4)
#   Updates: 474 (-40)
#
# =============================
#
# The Human Body by Tinybop
#     Sales: 317 (+4)
#   Updates: 42119 (+4)
#       IAP: 50 (+8)
#
# =============================


#     # Get apps sales
#     robot.http('https://api.appannie.com/v1/accounts/157063/sales?break_down=application+date&start_date=#{daybefore.formatted()}&end_date=#{yesterday.formatted()}')
#     .header('Authorization', bearer)
#     .get() (err, res, body) ->
#       if err
#         msg.send "Error: #{err}"
#         return
#       # if body
#       #   msg.send "Body: #{body}"
#       data = null
#       try
#         data = JSON.parse(body)
#       catch error
#
#       stats = {}
#       stats.date = data['sales_list'][0]['date']
#       stats.apps = []
#
#       Array::where = (query) ->
#         return [] if typeof query isnt "object"
#         hit = Object.keys(query).length
#         @filter (item) ->
#           match = 0
#           for key, val of query
#             match += 1 if item[key] is val
#           if match is hit then true else false
#
#       salesList = data['sales_list']
#
#       for item in salesList
#         itemId = item['app']
#         found = stats.apps.where id:itemId
#         if found.length == 0
#           newObject = {}
#           newObject.id = itemId
#           if itemId == '872615882'
#             newObject.name = 'Plants by Tinybop'
#           if itemId == '682046579'
#             newObject.name = 'The Human Body by Tinybop'
#           newObject.sales = item['units']['app']['downloads']
#           newObject.updates = item['units']['app']['updates']
#
#           stats.apps.push newObject
#
#       output = "/code #{stats.date}\n============================="
#
#       for app in stats.apps
#         output += """
#
#
#
# #{app['name']}
#     Sales: #{app['sales']}
#   Updates: #{app['updates']}
#
# =============================
# """
#
#       msg.send(output)
#       return

    # Get individual app details
    # robot.http("https://api.appannie.com/v1/apps/ios/app/682046579/details")
    # .header('Authorization', 'Bearer 3539b6983455bff0617d6d447b6d4b2fbf6ca3f2')
    # .get() (err, res, body) ->
    #   if err
    #     msg.send "Error: #{err}"
    #     return
    #   if res
    #     msg.send "Response: #{res}"
    #   if body
    #     msg.send "Body: #{body}"
    #   data = null
    #   try
    #     data = JSON.parse(body)
    #   catch error
    #     msg.send "Success: #{data}"
    #     return

    # Get individual app ranks
    # robot.http("https://api.appannie.com/v1/apps/ios/app/682046579/ranks?&start_date=2014-08-27&end_date=2014-08-28&countries=US+UK+CN+DE+RU+FR+JA")
    # .header('Authorization', 'Bearer 3539b6983455bff0617d6d447b6d4b2fbf6ca3f2')
    # .get() (err, res, body) ->
    #   if err
    #     msg.send "Error: #{err}"
    #     return
    #   if res
    #     msg.send "Response: #{res}"
    #   if body
    #     msg.send "Body: #{body}"
    #   data = null
    #   try
    #     data = JSON.parse(body)
    #   catch error
    #     msg.send "Success: #{data}"
    #     return
