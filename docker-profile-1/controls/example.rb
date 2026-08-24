# copyright: 2018, The Authors

title "Docker Resources Controls"

# ===== DOCKER IMAGES =====
# Control to test Docker images
control "docker-image-1.0" do
  impact 0.8
  title "Verify Docker image exists"
  desc "Check if a specific Docker image is present on the system"
  
  # Test if an image exists (replace 'nginx' with an image you have)
  describe docker_image('learnchef/inspec_nginx:latest') do
    it { should exist }
  end
end

control "docker-image-2.0" do
  impact 0.7
  title "Verify Docker image properties"
  desc "Check various properties of a Docker image"
  
  describe docker_image('learnchef/inspec_nginx:latest') do
    its('tag') { should_not be_empty }
    its('repo') { should include 'learnchef/inspec_nginx' }
  end
end

# ===== DOCKER CONTAINERS =====
# Control to test running Docker containers
control "docker-container-1.0" do
  impact 0.9
  title "Verify Docker container is running"
  desc "Check if a specific Docker container is running"
  
  # Replace 'my_container' with an actual running container name
  describe docker_container('my_container') do
    it { should exist }
    its('state.running') { should be true }
  end
end

control "docker-container-2.0" do
  impact 0.8
  title "Verify Docker container configuration"
  desc "Check container properties like ports, volumes, and environment"
  
  describe docker_container('my_container') do
    its('state.status') { should eq 'running' }
    its('restart_policy.max_retry_count') { should eq 0 }
  end
end

control "docker-container-3.0" do
  impact 0.7
  title "Verify container network settings"
  desc "Check network configuration of a container"
  
  describe docker_container('my_container') do
    its('network_settings.networks') { should_not be_empty }
  end
end

# ===== DOCKER NETWORKS =====
# Control to test Docker networks
control "docker-network-1.0" do
  impact 0.7
  title "Verify Docker network exists"
  desc "Check if a specific Docker network is present"
  
  describe docker_network('bridge') do
    it { should exist }
  end
end

control "docker-network-2.0" do
  impact 0.7
  title "Verify Docker network properties"
  desc "Check network configuration and connected containers"
  
  describe docker_network('bridge') do
    its('driver') { should eq 'bridge' }
  end
end

# ===== DOCKER SERVICES (Docker Swarm) =====
# Control to test Docker services (requires Swarm mode)
control "docker-service-1.0" do
  impact 0.7
  title "Verify Docker service exists"
  desc "Check if a Docker service is present (requires Docker Swarm)"
  
  # Uncomment if you have Docker Swarm running with a service
  # describe docker_service('my_service') do
  #   it { should exist }
  # end
end

# ===== DOCKER PLUGINS =====
# Control to test Docker plugins
control "docker-plugin-1.0" do
  impact 0.6
  title "Verify Docker plugin status"
  desc "Check if a Docker plugin is enabled"
  
  # Example: Check if a specific plugin is enabled
  # describe docker_plugin('plugin_name') do
  #   its('enabled') { should be true }
  # end
end

# ===== ALL IMAGES AND CONTAINERS =====
# Control to iterate through all images
control "docker-all-images-1.0" do
  impact 0.6
  title "Verify all Docker images"
  desc "Iterate through all Docker images and check basic properties"
  
  docker_images.images.each do |image|
    describe image do
      its('id') { should_not be_empty }
    end
  end
end

# Control to iterate through all containers
control "docker-all-containers-1.0" do
  impact 0.7
  title "Verify all running Docker containers"
  desc "Iterate through all containers and verify they meet compliance"
  
  docker_containers.containers.each do |container|
    describe container do
      its('status') { should include 'Up' }
    end
  end
end
