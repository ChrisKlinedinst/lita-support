require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "helpers/api"
require "helpers/url_parser"
require "lita/handlers/support"

Lita::Handlers::Support.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
