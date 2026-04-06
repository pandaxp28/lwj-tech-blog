#!/usr/bin/env ruby
# frozen_string_literal: true

require 'find'

module PostwritePublicationCleanup
  INTERNAL_PATTERNS = [
    /filecite.*?/m,
    /cite.*?/m,
    /filenavlist.*?/m,
    /navlist.*?/m
  ].freeze

  HTML_RELATED_FILES_SECTION = [
    /<h2[^>]*>関連ファイル<\/h2>.*?(?=<h2|<footer|<\/article>|<\/main>|\z)/mi,
    /<h3[^>]*>関連ファイル<\/h3>.*?(?=<h2|<h3|<footer|<\/article>|<\/main>|\z)/mi
  ].freeze

  def self.clean_html(content)
    cleaned = content.dup

    INTERNAL_PATTERNS.each do |pattern|
      cleaned.gsub!(pattern, '')
    end

    HTML_RELATED_FILES_SECTION.each do |pattern|
      cleaned.gsub!(pattern, '')
    end

    cleaned.gsub!(/\n{3,}/, "\n\n")
    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Find.find(site.dest) do |path|
    next unless path.end_with?('.html')
    next unless File.file?(path)

    original = File.read(path)
    cleaned = PostwritePublicationCleanup.clean_html(original)
    next if cleaned == original

    File.write(path, cleaned)
  end
end
