##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

	include Msf::Auxiliary::Report
	include Msf::Auxiliary::Scanner
	include Msf::Exploit::Remote::AFP

	def initialize(info={})
		super(update_info(info,
			'Name'         => 'Apple Filing Protocol Info Enumerator',
			'Description'  => %q{
				This module fetches AFP server information, including server name,
				network address, supported AFP versions, signature, machine type,
				and server flags.
			},
			'References'     =>
				[
					[ 'URL', 'https://developer.apple.com/library/mac/#documentation/Networking/Reference/AFP_Reference/Reference/reference.html' ]
				],
			'Author'       => [ 'Gregory Man <man.gregory[at]gmail.com>' ],
			'License'      => MSF_LICENSE
		))

		deregister_options('RHOST')
	end

	def run_host(ip)
		print_status("Scanning IP: #{ip.to_s}")
		begin
			connect
			response = get_info
			report(response)
		rescue ::Timeout::Error
		rescue ::Interrupt
			raise $!
		rescue ::Rex::ConnectionError, ::IOError, ::Errno::ECONNRESET, ::Errno::ENOPROTOOPT
		rescue ::Exception
			raise $!
			print_error("#{rhost}:#{rport} #{$!.class} #{$!}")
		ensure
			disconnect
		end
	end

	def report(response)
		report_info = "Server Name: #{response[:server_name]} \n" +
		" Server Flags: \n" +
		format_flags_report(response[:server_flags]) +
		" Machine Type: #{response[:machine_type]} \n" +
		" AFP Versions: #{response[:versions].join(', ')} \n" +
		" UAMs: #{response[:uams].join(', ')}\n" +
		" Server Signature: #{response[:signature]}\n" +
		" Server Network Address: \n" +
		format_addresses_report(response[:network_addresses]) +
		"  UTF8 Server Name: #{response[:utf8_server_name]}"
		print_status("#{rhost}:#{rport} APF:\n #{report_info}")

		report_note(:host => datastore['RHOST'],
			:proto => 'TCP',
			:port => datastore['RPORT'],
			:type => 'afp_server_info',
			:data => response)
	end

	def format_flags_report(parsed_flags)
		report = ''
		parsed_flags.each do |flag, val|
			report << "    *  #{flag}: #{val.to_s} \n"
		end
		return report
	end

	def format_addresses_report(parsed_network_addresses)
		report = ''
		parsed_network_addresses.each do |val|
			report << "    *  #{val.to_s} \n"
		end
		return report
	end
end
