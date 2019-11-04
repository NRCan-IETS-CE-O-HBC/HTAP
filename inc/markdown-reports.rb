

module MDRpts

  def MDRpts.newSection(sectionName,sectionLevel)
    secTxt = ""
    case sectionLevel
    when 1
      secTxt +="#{sectionName} \n"
      secTxt +="=".ljust(sectionName.length,"=")
    when 2
      secTxt +="#{sectionName} \n"
      secTxt +="-".ljust(sectionName.length,"-")
    else
      secTxt +="#".ljust(sectionLevel,"#")+" #{sectionName} \n"
    end

    return secTxt+"\n"
  end

  def MDRpts.newParagraph(txt)
    return txt+ "\n\n"
  end

    def MDRpts.newLine(txt)
    return txt+ "\n"
  end


  def MDRpts.newTable(tableData)

    # debug_on
    tableTxt = ""

    debug_out ("data:\n#{tableData.pretty_inspect}\n")

    columnNames = true

    if (tableData.is_a?(Hash))
      debug_out "processing hash\n"

    end

    if (tableData.is_a?(Array))
      debug_out "processing array\n"
      columnNames=false
    end

    tableHeader = ""
    tableRule = ""
    tableRows = Array.new
    colLenMax = Array.new
    colIndex = 0
    colData = Array.new
    tableData.each do | rawColumn |
      debug_out "??? #{rawColumn.pretty_inspect}???"
      columnName = ""
      if ( columnNames )
        name, colData = rawColumn
        columnName = name.gsub(/^noName.*$/, " ")
        colNameLen = columnName.length
      else
        colData = rawColumn
        colNameLen = 0
      end

      rowIndex = 0
      colLenMax[colIndex] = 0
      colData.each do | val |
        colLenMax[colIndex] = [colLenMax[colIndex],val.to_s.length+3, colNameLen].max
      end
      rightAlign = false
      rightAlign = true if ( ! colData[0].is_a?(String) )
      tableHeader += "|" +" "+ columnName.ljust(colLenMax[colIndex],)
      tableRule   += "|"
      tableRule   += ":" if (! rightAlign)
      tableRule   += "-".ljust(colLenMax[colIndex],"-")
      tableRule   += ":" if ( rightAlign)
      pushTxt = ""
      colData.each do | val |
        debug_out " VAL: #{val}, c#{colIndex},r#{rowIndex}\n"
        valTxt = "|"
        if ( rightAlign)
          valTxt += " #{val.to_s.rjust(colLenMax[colIndex]-1)} "
        else
          valTxt += " #{val.to_s.ljust(colLenMax[colIndex]-1)} "
        end
        pushTxt = (tableRows[rowIndex] || "" ) + valTxt
        tableRows[rowIndex] = pushTxt
        rowIndex += 1
      end
      colIndex += 1
    end
    tableRule += "|\n"
    tableHeader += "|\n"


    tableTxt = "\n"
    tableTxt += tableHeader
    tableTxt += tableRule
    tableRows.each do | row |
      tableTxt += row+"|\n"
    end
    #tableTxt += tableRule
    tableTxt += "\n\n"
    debug_out(tableTxt)

    return tableTxt
  end

  def MDRpts.newList(listData,format="unordered")
    listTxt = ""
    listSep = ""
    case format
    when "unordered"
      listSep = "  - "
    end
    listData.each do |item|
      listTxt += " #{listSep} #{item.gsub(/\n/," ")}\n"
    end
    return listTxt +"\n\n"
  end

  def MDRpts.shortenArrList(listData,listSep=",",len=5)
    listTxt = ""

    listLen = [len, listData.length].min
    remainder = listData.length - listLen
    first = true
    listData[0..listLen].each do |item|
      if (! first ) then listTxt +=", " end
      listTxt += "#{item}"
      first = false
    end
    if remainder > 0 then
      listTxt += " (+ #{remainder} more)"
    end
    return listTxt
  end

end
