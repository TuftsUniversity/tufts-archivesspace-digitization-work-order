# -*- coding: utf-8 -*-
require 'helper'

class TestRegressionChartFont04 < Test::Unit::TestCase
  def setup
    setup_dir_var
  end

  def teardown
    File.delete(@xlsx) if File.exist?(@xlsx)
  end

  def test_chart_font04
    @xlsx = 'chart_font04.xlsx'
    workbook  = WriteXLSX.new(@xlsx)
    worksheet = workbook.add_worksheet
    chart     = workbook.add_chart(:type => 'bar', :embedded => 1)

    # For testing, copy the randomly generated axis ids in the target xlsx file.
    chart.instance_variable_set(:@axis_ids, [43944960, 45705472])

    data = [
            [1, 2, 3,  4,  5],
            [2, 4, 6,  8, 10],
            [3, 6, 9, 12, 15]
           ]

    worksheet.write('A1', data)

    chart.add_series(:values => '=Sheet1!$A$1:$A$5')
    chart.add_series(:values => '=Sheet1!$B$1:$B$5')
    chart.add_series(:values => '=Sheet1!$C$1:$C$5')

    chart.set_title(
                    :name      => '=Sheet1!$A$1',
                    :name_font => { :bold => 0, :italic => 1 }
                    )

    chart.set_x_axis(
                     :name       => '=Sheet1!$A$2',
                     :name_font  => { :bold => 0, :italic => 1 }
                     )

    chart.set_y_axis(
                     :name       => '=Sheet1!$A$3',
                     :name_font  => { :bold => 1, :italic => 1 }
                     )

    worksheet.insert_chart('E9', chart)

    workbook.close
    compare_xlsx_for_regression(File.join(@regression_output, @xlsx), @xlsx,
                 nil,
                 { 'xl/charts/chart1.xml' => ['<c:pageMargins'] }
                 )
  end
end
