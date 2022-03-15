using CSV
using DataFrames
using Statistics
using Turing
using ReverseDiff
using Serialization

include("read.jl")
include("glm.jl")

Turing.setadbackend(:reversediff)

run_odor_CS()
run_tone_CS()



