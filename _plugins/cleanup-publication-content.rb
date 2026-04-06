#!/usr/bin/env ruby
# frozen_string_literal: true

# Build-time cleanup for publication output.
# This strips internal citation markers that should never appear on the public site,
# and removes the optional "関連ファイル" section from rendered content.

module PublicationCleanup
  INTERNAL_CITATION_PATTERNS = [
    /filecite.*?/m,
    /cite.*?/m,
    /filenavlist.*?/m,
    /navlist.*?/m
  ].freeze

  RELATED_FILES_SECTION = /^##\s+関連ファイル\s*$.*?(?=^##\s|\z)/m.freeze

  def self.clean(text)
    cleaned = text.dup

    INTERNAL_CITATION_PATTERNS.each do |pattern|
      cleaned.gsub!(pattern, "")
    end

    cleaned.gsub!(RELATED_FILES_SECTION, "")

    # Normalize extra blank lines left behind after cleanup.
    cleaned.gsub!(/\n{3,}/, "\n\n")
    cleaned.strip + "\n"
  end
end

[:posts, :pages, :documents].each do |scope|
  Jekyll::Hooks.register scope, :pre_render do |doc|
    next unless doc.respond_to?(:content) && doc.content.is_a?(String)

    doc.content = PublicationCleanup.clean(doc.content)
  end
end
