#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzzzzzzHideLegacyWinMaintenanceToolPosts
  HIDDEN_POST_PATHS = [
    '_posts/2026-04-06-win-maintenance-tool-overview.md',
    '_posts/2026-04-06-win-maintenance-tool-roadmap.md',
    '_posts/2026-04-06-win-maintenance-tool-roadmap-published.md'
  ].freeze

  def self.hidden?(doc)
    return false unless doc.respond_to?(:relative_path)

    HIDDEN_POST_PATHS.include?(doc.relative_path.to_s)
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  if site.respond_to?(:posts) && site.posts.respond_to?(:docs)
    site.posts.docs.reject! { |doc| ZzzzzzzzzHideLegacyWinMaintenanceToolPosts.hidden?(doc) }
  end

  if site.respond_to?(:collections) && site.collections['posts']
    site.collections['posts'].docs.reject! { |doc| ZzzzzzzzzHideLegacyWinMaintenanceToolPosts.hidden?(doc) }
  end
end
