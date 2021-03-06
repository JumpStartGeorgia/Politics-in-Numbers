# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder
# are already added.
Rails.application.config.assets.precompile += %w( highcharts.js highcharts-exporting.js
                                                highcharts-offline-exporting.js highcharts-grouped-categories.js
                                                datatables.buttons.html5.min.js datatables.buttons.min.js
                                                admin.js admin.css explore.js explore.css crypto.min.js
                                                in-media.css in-media.js readmore.min.js
                                                about.css home.css home.js download.js download.css
                                              )
