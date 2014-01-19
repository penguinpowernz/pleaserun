require "testenv"
require "pleaserun/upstart"

describe PleaseRun::Upstart do
  it "inherits correctly" do
    insist { PleaseRun::Upstart.ancestors }.include?(PleaseRun::Base)
  end

  context "#files" do
    subject do
      runner = PleaseRun::Upstart.new("1.10")
      runner.name = "fancypants"
      next runner
    end

    let(:files) { subject.files.collect { |path, content| path } }

    it "emits a file in /etc/init/" do
      insist { files }.include?("/etc/init/fancypants.conf")
    end

    it "emits a file in /etc/init.d/" do
      insist { files }.include?("/etc/init.d/fancypants")
    end
  end

  context "#install_actions" do
    subject do
      runner = PleaseRun::Upstart.new("1.10")
      runner.name = "fancypants"
      next runner
    end

    it "has no install actions" do
      insist { subject.install_actions }.empty?
    end
  end

  context "deployment" do
    partytime = (superuser? && platform?("linux"))
    it "cannot be attempted", :if => !partytime do
      pending("we are not the superuser") unless superuser?
      pending("platform is not linux") unless platform?("linux")
    end

    context "as the super user", :if => partytime do
      subject { PleaseRun::Upstart.new("1.10") }

      before do
        subject.name = "example"
        subject.user = "root"
        subject.program = "/bin/sh"
        subject.args = [ "-c", "echo hello world; sleep 5" ]

        subject.files.each do |path, content|
          File.write(path, content)
        end
        subject.install_actions.each do |command|
          system(command)
          raise "Command failed: #{command}" unless $?.success?
        end
      end

      after do
        system_quiet("initctl stop #{subject.name}")
        subject.files.each do |path, content|
          File.unlink(path) if File.exist?(path)
        end

        # Remove the logs, too.
        [ "/var/log/#{subject.name}.out", "/var/log/#{subject.name}.err" ].each do |log|
          File.unlink(log) if File.exist?(log)
        end
      end

      it "should install" do
        system_quiet("initctl status #{subject.name}")
        insist { $? }.success?
      end

      it "should start" do
        system_quiet("initctl start #{subject.name}")
        insist { $? }.success?

        # Starting an already-started job will fail
        system_quiet("initctl start #{subject.name}")
        reject { $? }.success?

        system_quiet("initctl status #{subject.name}")
        insist { $? }.success?
      end

      it "should stop" do
        system_quiet("initctl start #{subject.name}")
        insist { $? }.success?
        system_quiet("initctl stop #{subject.name}")
        insist { $? }.success?

        # Stopping an already-stopped job will fail
        system_quiet("initctl stop #{subject.name}")
        reject { $? }.success?
      end
    end
  end # real tests
end