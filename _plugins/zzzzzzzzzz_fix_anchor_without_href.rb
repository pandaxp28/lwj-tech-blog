#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzzzzzzzFixAnchorWithoutHref
  BAD_ANCHOR_PATTERN = /<a(?![^>]*\bhref=)[^>]*>(.*?)<\/a>/mi.freeze

  def self.clean_html(text)
    cleaned = text.dup
    cleaned.gsub!(BAD_ANCHOR_PATTERN, '\1')
    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)

    original = File.read(path)
    cleaned = ZzzzzzzzzzFixAnchorWithoutHref.clean_html(original)
    next if cleaned == original

    File.write(path, cleaned)
  end
end
