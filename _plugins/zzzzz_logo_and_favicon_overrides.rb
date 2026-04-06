#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'

module ZzzzzLogoAndFaviconOverrides
  SVG = <<~SVG.freeze
    <svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
      <rect width="512" height="512" rx="96" fill="#111827"/>
      <rect x="44" y="44" width="424" height="424" rx="84" fill="#0f172a" stroke="#22c55e" stroke-width="16"/>
      <text x="256" y="308" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="156" font-weight="700" fill="#f8fafc">LWJ</text>
      <circle cx="402" cy="112" r="28" fill="#22c55e"/>
    </svg>
  SVG

  DATA_URI = "data:image/svg+xml,#{CGI.escape(SVG).gsub('+', '%20')}"

  FAVICON_PATTERNS = [
    /<link[^>]+rel=["'][^"']*icon[^"']*["'][^>]+href=["'][^"']+["'][^>]*>/i,
    /<link[^>]+href=["'][^"']+["'][^>]+rel=["'][^"']*icon[^"']*["'][^>]*>/i,
    /<link[^>]+rel=["']apple-touch-icon["'][^>]*>/i,
    /<meta[^>]+name=["']msapplication-TileImage["'][^>]*>/i
  ].freeze

  def self.apply_site_config(site)
    site.config['avatar'] = DATA_URI
  end

  def self.inject_favicon(html)
    cleaned = html.dup
    FAVICON_PATTERNS.each { |pattern| cleaned.gsub!(pattern, '') }

    favicon_markup = <<~HTML
      <link rel="icon" type="image/svg+xml" href="#{DATA_URI}">
      <link rel="apple-touch-icon" href="#{DATA_URI}">
    HTML

    if cleaned.include?('</head>')
      cleaned.sub!('</head>', "#{favicon_markup}</head>")
    end

    cleaned
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  ZzzzzLogoAndFaviconOverrides.apply_site_config(site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    original = File.read(path)
    cleaned = ZzzzzLogoAndFaviconOverrides.inject_favicon(original)
    next if cleaned == original
    File.write(path, cleaned)
  end
end
