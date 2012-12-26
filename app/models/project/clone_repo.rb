class Project
  class CloneRepo

    def self.perform(project_id)
      begin
        project = Project.find(project_id)
      rescue ActiveRecord::RecordNotFound
        return
      end

      Strano::Repo.clone project.url

      capvt=project.cap(%w(-vT)).task_list(:all).sort_by(&:fully_qualified_name).inject({}) {|h,t| h[t.fully_qualified_name]=t.desc; h}
            capvt.each{|name,desc| Task.create name: name, description: desc, project_id: project.id, author_id:1}

      Project.update_all({:updated_at => Time.now,
                          :cloned_at => Time.now,
                          :pulled_at => Time.now,
                          :pull_in_progress => false},
                          :id => project_id)
    end

    def self.perform_async project_id
      Job.create! :project_id => project_id, :visible => false,
        :notes => 'CloneRepo'
    end
  end
end
