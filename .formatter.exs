[
  plugins: [Styler],
  styler: [
    # Match mix.exs elixir floor so Styler only applies rewrites safe for consumers.
    minimum_supported_elixir_version: "1.14.0"
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
