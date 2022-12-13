# -*- coding: utf-8 -*-
require 'helper'

class TestRegressionImage15 < Test::Unit::TestCase
  def setup
    setup_dir_var
  end

  def teardown
    File.delete(@xlsx) if File.exist?(@xlsx)
  end

  def test_image15
    @xlsx = 'image15.xlsx'
    workbook  = WriteXLSX.new(@xlsx)
    worksheet = workbook.add_worksheet

    worksheet.set_row(1, 4.5)
    worksheet.set_row(2, 35.25)
    worksheet.set_column('C:E', 3.29)
    worksheet.set_column('F:F', 10.71)

    worksheet.insert_image('C2',
                           'test/regression/images/logo.png', 13, 2)

    workbook.close
    compare_xlsx_for_regression(File.join(@regression_output, @xlsx), @xlsx)
  end
end
