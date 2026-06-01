-- energy_analyzer.lua: Energy symplecticity analyzer

local EnergyAnalyzer = {}

function EnergyAnalyzer.new()
    local self = setmetatable({}, {__index = EnergyAnalyzer})
    self:reset()
    return self
end

function EnergyAnalyzer:reset()
    self.initial_energy = nil
    self.average_energy = 0
    self.errors = {}
    self.max_error = 0
    self.min_error = 0
    self.sample_count = 0
    self.pos_error_count = 0
    self.neg_error_count = 0
    self.pos_error_sum = 0
    self.neg_error_sum = 0
end

function EnergyAnalyzer:record(current_energy)
    if not self.initial_energy then
        self.initial_energy = current_energy
        self.average_energy = current_energy
    end

    self.sample_count = self.sample_count + 1
    self.average_energy = self.average_energy + (current_energy - self.average_energy) / self.sample_count

    local error = current_energy - self.initial_energy
    
    if error > 0 then
        self.pos_error_count = self.pos_error_count + 1
        self.pos_error_sum = self.pos_error_sum + error
    elseif error < 0 then
        self.neg_error_count = self.neg_error_count + 1
        self.neg_error_sum = self.neg_error_sum + math.abs(error)
    end

    table.insert(self.errors, error)
    if #self.errors > 1000 then table.remove(self.errors, 1) end -- Limit error record length to prevent unbounded memory growth
    
    if error > self.max_error then
        self.max_error = error
    end
    if error < self.min_error then
        self.min_error = error
    end
end

function EnergyAnalyzer:get_deviation()
    if not self.initial_energy or self.initial_energy == 0 then
        return 0
    end
    local current = self.errors[#self.errors] or 0
    return math.abs(current / self.initial_energy)
end

function EnergyAnalyzer:get_variance()
    if #self.errors < 2 then return 0 end
    
    local sum = 0
    for _, e in ipairs(self.errors) do
        sum = sum + e
    end
    local mean = sum / #self.errors
    
    local variance = 0
    for _, e in ipairs(self.errors) do
        variance = variance + (e - mean)^2
    end
    return variance / #self.errors
end

function EnergyAnalyzer:get_std_deviation()
    return math.sqrt(self:get_variance())
end

function EnergyAnalyzer:get_symplecticity()
    if #self.errors < 10 then return 0 end
    
    local sign_changes = 0
    local mean = 0
    for _, e in ipairs(self.errors) do
        mean = mean + e
    end
    mean = mean / #self.errors
    
    for i = 2, #self.errors do
        local prev = self.errors[i-1] - mean
        local curr = self.errors[i] - mean
        if prev * curr < 0 then
            sign_changes = sign_changes + 1
        end
    end
    
    return sign_changes / (#self.errors - 1)
end

function EnergyAnalyzer:get_drift_rate()
    if #self.errors < 2 then return 0 end
    local first = self.errors[1]
    local last = self.errors[#self.errors]
    return (last - first) / self.sample_count
end

function EnergyAnalyzer:is_symplectic(threshold)
    threshold = threshold or 0.1
    local drift = math.abs(self:get_drift_rate())
    local sym = self:get_symplecticity()
    return drift < threshold and sym > 0.3
end

function EnergyAnalyzer:get_report()
    local current_error = self.errors[#self.errors] or 0
    
    -- Frequency Bias
    local total_counted = self.pos_error_count + self.neg_error_count
    local freq_bias = 0
    if total_counted > 0 then
        freq_bias = (self.pos_error_count - self.neg_error_count) / total_counted
    end

    -- Magnitude Bias (more balanced comparison)
    local total_mag = self.pos_error_sum + self.neg_error_sum
    local mag_bias = 0
    if total_mag > 0 then
        mag_bias = (self.pos_error_sum - self.neg_error_sum) / total_mag
    end

    return {
        initial_energy = self.initial_energy,
        average_energy = self.average_energy,
        current_error = current_error,
        deviation = self:get_deviation(),
        variance = self:get_variance(),
        std_dev = self:get_std_deviation(),
        max_error = self.max_error,
        min_error = self.min_error,
        drift_rate = self:get_drift_rate(),
        symplecticity = self:get_symplecticity(),
        sample_count = self.sample_count,
        pos_count = self.pos_error_count,
        neg_count = self.neg_error_count,
        freq_bias = freq_bias,
        mag_bias = mag_bias
    }
end

return EnergyAnalyzer