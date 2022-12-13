# -*- coding: utf-8 -*-
require 'helper'

class TestRegressionChartPoints02 < Test::Unit::TestCase
  def setup
    setup_dir_var
  end

  def teardown
    File.delete(@xlsx) if File.exist?(@xlsx)
  end

  def test_chart_points02
    @xlsx = 'chart_points02.xlsx'
    workbook  = WriteXLSX.new(@xlsx)
    worksheet = workbook.add_worksheet
    chart     = workbook.add_chart(:type => 'pie', :embedded => 1)

    data = [
            [2, 5, 4, 1, 7, 4]
           ]

    worksheet.write('A1', data)

    chart.add_series(
                     :values => '=Sheet1!$A$1:$A$6',
                     :points => [
                                 nil,
                                 { :border => { :color => 'red', :dash_type => 'square_dot' } },
                                 nil,
                                 { :fill => { :color => 'yellow' } }
                                ]
                     )

    worksheet.insert_chart('E9', chart)

    workbook.close
    compare_xlsx_for_regression(File.join(@regression_output, @xlsx), @xlsx)
  end
end
