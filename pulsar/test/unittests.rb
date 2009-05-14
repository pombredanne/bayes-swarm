# = Test : UnitTests runner
# Executes the suite of available unit tests.
#
# To run the tests, use the +Runner+ as usual, but remember to add a +runner+
# option to tell Test::Unit which suite runner to use.
#
#   ruby runner.rb -c test_shoal_options.yml \
#                  -f test/unittests \
#                  --runner=console
#
# The +test_shoal_options.yml+ should contain execution options suitable
# for unit testing.
#
# To add a new test to the suite:
#   * Create a new Test::Unit::TestCase inside the unit/ folder.
#     See +blender_unit.rb+ as an example
#   * add a +require+ line to this file
#
# It's that simple.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.

require 'test/unit'

require 'test/unit/blender_unit'
