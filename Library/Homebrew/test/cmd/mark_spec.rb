# frozen_string_literal: true

require "cmd/mark"
require "cmd/shared_examples/args_parse"
require "tab"

RSpec.describe Homebrew::Cmd::Mark do
  it_behaves_like "parseable arguments"

  describe "integration tests", :integration_test do
    def installed_on_request?(formula)
      # `brew` subprocesses can change the tab, invalidating the cached values.
      Tab.clear_cache
      Tab.for_formula(formula).installed_on_request
    end

    def installed_as_dependency?(formula)
      # `brew` subprocesses can change the tab, invalidating the cached values.
      Tab.clear_cache
      Tab.for_formula(formula).installed_as_dependency
    end

    let(:testball) { Formula["testball"] }
    let(:baz) { Formula["baz"] }

    before do
      install_test_formula "testball", tab_attributes: {
        "installed_on_request"    => false,
        "installed_as_dependency" => true,
      }
      setup_test_formula "baz"
    end

    it "marks or unmarks a formula as installed on request" do
      expect(installed_on_request?(testball)).to be false

      expect { brew "mark", "--installed-on-request", "testball" }
        .to be_a_success
        .and output(/testball is now marked as installed on request/).to_stdout
        .and not_to_output.to_stderr
      expect(installed_on_request?(testball)).to be true

      expect { brew "mark", "--installed-on-request", "testball" }
        .to be_a_success
        .and output(/testball is already marked as installed on request/).to_stdout
        .and not_to_output.to_stderr
      expect(installed_on_request?(testball)).to be true

      expect { brew "mark", "--no-installed-on-request", "testball" }
        .to be_a_success
        .and output(/testball is now marked as not installed on request/).to_stdout
        .and not_to_output.to_stderr
      expect(installed_on_request?(testball)).to be false
    end

    it "marks or unmarks a formula as installed as dependency" do
      expect(installed_as_dependency?(testball)).to be true

      expect { brew "mark", "--no-installed-as-dependency", "testball" }
        .to be_a_success
        .and output(/testball is now marked as not installed as dependency/).to_stdout
        .and not_to_output.to_stderr
      expect(installed_as_dependency?(testball)).to be false

      expect { brew "mark", "--no-installed-as-dependency", "testball" }
        .to be_a_success
        .and output(/testball is already marked as not installed as dependency/).to_stdout
        .and not_to_output.to_stderr
      expect(installed_as_dependency?(testball)).to be false

      expect { brew "mark", "--installed-as-dependency", "testball" }
        .to be_a_success
        .and output(/testball is now marked as installed as dependency/).to_stdout
        .and not_to_output.to_stderr
      expect(installed_as_dependency?(testball)).to be true
    end

    it "raises an error when a formula is not installed" do
      expect { brew "mark", "--installed-on-request", "testball", "baz" }
        .to be_a_failure
        .and not_to_output.to_stdout
        .and output(/baz is not installed/).to_stderr
    end
  end
end
