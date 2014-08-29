# Description:
#   Fetches app status info from App Annie
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#
# Author:
#   Josh Stewart
#


module.exports = (robot) ->
  robot.respond /app status/i, (msg) ->
    unless process.env.APP_ANNIE_KEY?
      msg.send "Please specify your App Annie API key in APP_ANNIE_KEY"
      return

    msg.send "Checking now ..."

    # Get apps sales
    robot.http("https://api.appannie.com/v1/accounts/157063/sales?break_down=application+date&start_date=2014-08-27&end_date=2014-08-28")
    .header('Authorization', 'Bearer #{process.env.APP_ANNIE_KEY}')
    # Add API key to heroku
    .get() (err, res, body) ->
      if err
        msg.send "Error: #{err}"
        return
      if body
        msg.send "Body: #{body}"
      data = null
      try
        data = JSON.parse(body)
      catch error

      stats = {}
      stats.date = data['sales_list'][0]['date']
      stats.apps = []

      Array::where = (query) ->
        return [] if typeof query isnt "object"
        hit = Object.keys(query).length
        @filter (item) ->
          match = 0
          for key, val of query
            match += 1 if item[key] is val
          if match is hit then true else false

      salesList = data['sales_list']
      msg.send "salesList: #{salesList}"

      for item in salesList
        itemId = item['app']
        msg.send "itemId: #{itemId}"

        found = stats.apps.where id:itemId

        if found.length == 0
          newObject = {}
          newObject.id = itemId
          if itemId == '872615882'
            newObject.name = 'Plants by Tinybop'
          if itemId == '682046579'
            newObject.name = 'The Human Body by Tinybop'
          newObject.sales = item['units']['app']['downloads']
          newObject.updates = item['units']['app']['updates']

          stats.apps.push newObject

      output = "#{stats.date}\n============================="

      for app in stats.apps
        output += """



#{app['name']}
    Sales: #{app['sales']}
  Updates: #{app['updates']}

=============================
"""

      msg.send(output)
      return

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