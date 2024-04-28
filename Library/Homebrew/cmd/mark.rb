# typed: strict
# frozen_string_literal: true

require "abstract_command"
require "formula"
require "tab"

module Homebrew
  module Cmd
    class Mark < AbstractCommand
      cmd_args do
        description <<~EOS
          Mark or unmark <formula> as installed on request, or installed as
          dependency. This can be useful if you want to control whether an
          installed formula should be removed by `brew autoremove`.
        EOS
        switch "--installed-on-request",
               description: "Mark <formula> as installed on request."
        switch "--no-installed-on-request",
               description: "Mark <formula> as not installed on request."
        switch "--installed-as-dependency",
               description: "Mark <formula> as installed as dependency."
        switch "--no-installed-as-dependency",
               description: "Mark <formula> as not installed as dependency."

        conflicts "--installed-on-request", "--no-installed-on-request"
        conflicts "--installed-as-dependency", "--no-installed-as-dependency"

        named_args :formula, min: 1
      end

      sig { override.void }
      def run
        installed_on_request = if args.installed_on_request?
          true
        elsif args.no_installed_on_request?
          false
        end
        installed_as_dependency = if args.installed_as_dependency?
          true
        elsif args.no_installed_as_dependency?
          false
        end
        raise UsageError, "No marking option specified." if installed_on_request.nil? && installed_as_dependency.nil?

        formulae = args.named.to_formulae
        if (formula_not_installed = formulae.find { |f| !f.any_version_installed? })
          odie "#{formula_not_installed.name} is not installed."
        end

        formulae.each do |formula|
          mark_formula formula, installed_on_request:, installed_as_dependency:
        end
      end

      private

      sig {
        params(
          formula:                 Formula,
          installed_on_request:    T.nilable(T::Boolean),
          installed_as_dependency: T.nilable(T::Boolean),
        ).void
      }
      def mark_formula(formula, installed_on_request:, installed_as_dependency:)
        tab = Tab.for_formula(formula)
        raise ArgumentError, "Tab file for #{formula.name} does not exist." unless tab.tabfile.exist?

        unchanged_statuses = []
        changed_statuses = []
        unless installed_on_request.nil?
          status = "#{installed_on_request ? "" : "not "}installed on request"
          if tab.installed_on_request ^ installed_on_request
            changed_statuses << status
          else
            unchanged_statuses << status
          end
        end
        unless installed_as_dependency.nil?
          status = "#{installed_as_dependency ? "" : "not "}installed as dependency"
          if tab.installed_as_dependency ^ installed_as_dependency
            changed_statuses << status
          else
            unchanged_statuses << status
          end
        end

        unless unchanged_statuses.empty?
          ohai "#{formula.name} is already marked as #{unchanged_statuses.to_sentence}."
        end

        return if changed_statuses.empty?

        tab.installed_on_request = installed_on_request unless installed_on_request.nil?
        tab.installed_as_dependency = installed_as_dependency unless installed_as_dependency.nil?
        tab.write
        ohai "#{formula.name} is now marked as #{changed_statuses.to_sentence}."
      end
    end
  end
end
