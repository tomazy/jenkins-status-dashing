class JenkinsStatus < Dashing::Job

  protected

  def do_execute
    build_status
  end

  private

  def load_project(url, project)
    client = Jenkins::Client.new(url)
    client.load_project(project)
  end

  def build_status
    project = load_project(config[:url], config[:project])

    status = {}
    status[:code]  = config[:code]
    status[:title] = project.display_name
    status[:score] = project.health_score

    if b = project.last_build
      status[:timestamp]  = b.timestamp
    end

    status[:builds] = project.last_builds.map do |build|
      result = {
        success:   build.success?,
        timestamp: build.timestamp,
        duration:  build.duration,
        building:  build.building
      }

      if cs = build.changesets.first
        result[:change_author] = cs.author
        result[:change_comment] = cs.comment
      end

      result
    end

    status
  end
end
