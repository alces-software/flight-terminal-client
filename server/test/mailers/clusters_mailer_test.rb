require 'test_helper'

class ClustersMailerTest < ActionMailer::TestCase
  test "about to launch" do
    mail = ClustersMailer.about_to_launch(launch_config)
    assert_equal 'Your Alces Flight Launch HPC cluster my-cluster is now boarding', mail.subject
    assert_equal [launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('about_to_launch').join, mail.text_part.body.to_s
  end

  test "about to launch with token" do
    mail = ClustersMailer.about_to_launch(token_launch_config)
    assert_equal 'Your Alces Flight Launch HPC cluster my-cluster is now boarding', mail.subject
    assert_equal [token_launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('about_to_launch_with_token').join, mail.text_part.body.to_s
  end

  test "about to launch with token and runtime" do
    mail = ClustersMailer.about_to_launch(token_runtime_launch_config)
    assert_equal 'Your Alces Flight Launch HPC cluster my-cluster is now boarding', mail.subject
    assert_equal [token_runtime_launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('about_to_launch_with_token_and_runtime').join, mail.text_part.body.to_s
  end

  test "launching" do
    arn = 'arn:aws:cloudformation:us-east-1:700366075446:stack/flight-cluster-bens-test-2/a4c95470-099e-11e7-8ce5-500c217b4a9a'

    mail = ClustersMailer.launching(launch_config, arn)
    assert_equal "Your Alces Flight Launch HPC cluster #{launch_config.name} is in taxi for take-off", mail.subject
    assert_equal [launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('launching').join, mail.text_part.body.to_s
  end

  test "launched" do
    output = File.read(Rails.root.join('test/mailers/previews/output.sample'))

    mail = ClustersMailer.launched(launch_config, output)
    assert_equal "Your Alces Flight Launch HPC cluster #{launch_config.name} is in flight and ready for use", mail.subject
    assert_equal [launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('launched').join, mail.text_part.body.to_s
  end

  test "launched with token" do
    output = File.read(Rails.root.join('test/mailers/previews/output.sample'))

    mail = ClustersMailer.launched(token_runtime_launch_config, output)
    assert_equal "Your Alces Flight Launch HPC cluster #{token_runtime_launch_config.name} is in flight and ready for use", mail.subject
    assert_equal [token_runtime_launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('launched_with_token').join, mail.text_part.body.to_s
  end

  test "failed" do
    output = File.read(Rails.root.join('test/mailers/previews/failed.deleted-whilst-creating.sample'))
    arn = 'arn:aws:cloudformation:us-east-1:700366075446:stack/flight-cluster-bens-test-2/a4c95470-099e-11e7-8ce5-500c217b4a9a'

    mail = ClustersMailer.failed(token_launch_config, output, arn)
    assert_equal "Your Alces Flight Launch HPC cluster #{token_launch_config.name} has failed to launch", mail.subject
    assert_equal [token_launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    assert_equal read_fixture('failed').join, mail.text_part.body.to_s
  end

  def launch_config
    ClusterLaunchConfig.new(
      email: 'me@example.com',
      name: 'my-cluster',
      spec: ClusterSpec.new(
        meta: {
          'title' => 'Small SGE bioinformatics cluster',
          'titleLowerCase' => 'small SGE bioinformatics cluster',
        }
      ),
    )
  end

  def token_launch_config
    launch_config.tap do |lc|
      lc.token = 'carelessly-spoil-coffee'
    end
  end

  def token_runtime_launch_config
    token_launch_config.tap do |lc|
      lc.spec.args = ['--runtime', '240', '--solo']
    end
  end
end
