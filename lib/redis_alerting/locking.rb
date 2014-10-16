module RedisAlerting
  class Locking
    def initialize(pidfile)
      @pidfile = pidfile || "/tmp/redis_alerting.pid"
      @pid = File.read(@pidfile).chomp if File.exists? @pidfile
    end

    def lock
      raise StandardError, "Alerting already running on pid #{pid}" if pid_running?

      warn "Overwriting old pidfile (last pid #{pid})" unless @pid.nil?
      File.open(@pidfile,"w") {|f| f.write Process.pid }
    end

    def unlock
      File.delete(pidfile)
    end

    def pid_running?
      return false if @pid.nil?

      begin
        Process.kill(0, pid)
        return true
      rescue Errno::EPERM
        return false
      rescue Errno::ESRCH
        return false
      rescue
        return false
      end
    end
  end
end