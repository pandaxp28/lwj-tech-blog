#!/usr/bin/env ruby
# frozen_string_literal: true

# Ensure posts dated later on the same day are still published.
Jekyll::Hooks.register :site, :after_init do |site|
  site.config['future'] = true
end
