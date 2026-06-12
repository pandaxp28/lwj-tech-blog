#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzzzDisablePwaAndCache
  MANIFEST_PATTERNS = [
    /<link[^>]+rel=["']manifest["'][^>]*>/i,
    /<meta[^>]+name=["']theme-color["'][^>]*>/i
  ].freeze

  SERVICE_WORKER_PATTERNS = [
    /<script[^>]*>.*?navigator\.serviceWorker.*?<\/script>/mi,
    /<script[^>]+src=["'][^"']*sw-register[^"']*["'][^>]*><\/script>/mi
  ].freeze

  def self.apply_site_config(site)
    pwa = site.config['pwa'] || {}
    pwa['enabled'] = false
    if pwa['cache'].is_a?(Hash)
      pwa['cache']['enabled'] = false
    else
      pwa['cache'] = { 'enabled' => false }
    end
    site.config['pwa'] = pwa
  end

  def self.clean_html(html)
    cleaned = html.dup
    MANIFEST_PATTERNS.each { |pattern| cleaned.gsub!(pattern, '') }
    SERVICE_WORKER_PATTERNS.each { |pattern| cleaned.gsub!(pattern, '') }
    cleaned
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  ZzzzzzDisablePwaAndCache.apply_site_config(site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    original = File.read(path)
    cleaned = ZzzzzzDisablePwaAndCache.clean_html(original)
    next if cleaned == original
    File.write(path, cleaned)
  end
end
