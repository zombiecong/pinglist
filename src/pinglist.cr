require "./pinglist/*"
require "commander"
require "bit_array"

# TODO: Write documentation for `Pinglist`

def getIpList(filename : String)
  list = [] of String

  # version 1 , just add 1
  File.read_lines(filename).each { |a|
    list = list + ipParse(a)
  # ?\.[0-9]*\.[0-9]*\.(0)\/[0-9]*
  }

  list
end

def ipParse(ip : String)
  r1 = ip.split("/")

  n = 32 - r1[1].to_i

  res = iptoint(r1[0])

  r = (res >> n << n) + 1
  r2 = r + (1 << n) - 2

  # puts intoip(r)
  # puts intoip(r2)

  iplist = [] of String
  (r...r2).each do |rnum|
    # puts intoip(rnum)
    iplist = iplist + [intoip(rnum)]
  end
  iplist
end

def ping(iplist : Array(String))
  ch = Channel(Array(String)).new

  iplist.each { |x|
    puts "ping #{x}..."
    spawn do
      # puts 1
      output = IO::Memory.new
      Process.run("ping", ["-c 3", x], output: output)
      # puts output.to_s

      if res = /[0-9.]*\/([0-9.]*)\/[0-9.]*\/[0-9.]*/.match(output.to_s)
        # puts res[1]
        # ch.send({x => res[1]})
        ch.send([x, res[1]])
      else
        ch.send([x, "-1"])
      end
    end
  }

  our_file = File.open "result.txt", "a"

  iplist.size.times do
    res = ch.receive

    our_file.puts "#{res[0]} #{res[1]}"
  end

  our_file.close
end

def iptoint(ip : String)
  r2 = ip.split(".")
  res = 0.to_u32
  r2.each_with_index do |num, i|
    res = res | (num.to_u32 << ((r2.size - i - 1)*8))
  end

  res
end

def intoip(num : UInt32)
  "#{getByte(num, 3)}.#{getByte(num, 2)}.#{getByte(num, 1)}.#{getByte(num, 0)}"
end

def getByte(num : UInt32, index : Int)
  (num >> (8*index)) & 0xff
end

module Pinglist
  cli = Commander::Command.new do |cmd|
    cmd.use = "pinglist"
    cmd.long = "ping a list of server"

    cmd.flags.add do |flag|
      flag.name = "infile"
      flag.short = "-i"
      flag.long = "--infile"
      flag.default = "~/iplist.txt"
      flag.description = "input ip list"
    end

    cmd.flags.add do |flag|
      flag.name = "outfile"
      flag.short = "-o"
      flag.long = "--outfile"
      flag.default = "~/result.txt"
      flag.description = "ping test result"
    end

    cmd.run do |options, arguments|
      infile = options.string["infile"]
      outfile = options.string["outfile"]

      iplist = getIpList(infile)
      iplist.each_slice(100) do |slice|
        ping(slice)
      end
      # puts iplist.size
      # ping(iplist)
    end
  end

  Commander.run(cli, ARGV)
end
