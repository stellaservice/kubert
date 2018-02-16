class KubectlProxy
  def self.enable
    new.enable
  end

  def enable
    if running?
      stop
      start
      block_till_started
    else
      start
      block_till_started
    end
  end

  def start
    pid = fork { `kubectl proxy` }
    Process.detach(pid)
  end

  def stop
    Process.kill(1, running_pid) == 1
  end

  def running?
   !`ps aux | grep '[k]ubectl proxy'`.empty?
  end

  private

  def block_till_started
    loop do
      break if running?
    end
  end

  def running_pid
    `ps aux | grep '[k]ubectl proxy' | awk '{ print $2 }'`.strip.to_i
  end

end
