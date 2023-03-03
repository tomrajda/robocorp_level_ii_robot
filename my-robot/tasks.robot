*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 1. Saves the order HTML receipt as a PDF file.
...                 2. Saves the screenshot of the ordered robot.
...                 3. Embeds the screenshot of the robot to the PDF receipt.
...                 4. Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
#Config variables
${url1}                 https://robotsparebinindustries.com/#/robot-order
${url2}                 https://robotsparebinindustries.com/orders.csv
${browser}              chrome
${file_name}            orders.csv
${pdf_folder}           ${OUTPUT_DIR}${/}pdf_files
${pdfs}                 ${OUTPUT_DIR}${/}pdfs.zip
${png_folder}           ${OUTPUT_DIR}${/}png_files
${retry_number}         10x
${retry_interval}       2s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website    ${url1}    ${browser}
    ${orders}    Get orders    ${file_name}

    FOR    ${order}    IN    @{orders}
        Close PopUp
        Fill the form    ${order}
        Wait Until Keyword Succeeds    ${retry_number}    ${retry_interval}    Preview the robot
        Wait Until Keyword Succeeds    ${retry_number}    ${retry_interval}    Submit the order
        ${pdf}    ${orderid}    Store the order receipt as a PDF file    ${pdf_folder}
        ${png}    Take a screenshot of the robot image    ${orderid}    ${png_folder}
        Embed the robot screenshot to the receipt PDF file    ${png}    ${pdf}
        Go to order another robot
    END

    Create a ZIP file of receipt PDF files    ${pdf_folder}    ${pdfs}
    [Teardown]    Logout and Close Browser


*** Keywords ***
Open the robot order website
    [Arguments]    ${url1}    ${browser}

    #Open Browser
    Open Available Browser    ${url1}    ${browser}

Get orders
    [Arguments]    ${file_name}

    # Download CSV file and convert to table
    Download    ${url2}    overwrite=True
    ${orders}    Read table from CSV    ${file_name}    header=True

    RETURN    ${orders}

Close PopUp
    # Close PopUp
    Click Button    OK

Fill the form
    [Arguments]    ${order}

    # Variables from table
    Set Local Variable    ${head}    ${order}[Head]
    Set Local Variable    ${body}    ${order}[Body]
    Set Local Variable    ${legs}    ${order}[Legs]
    Set Local Variable    ${address}    ${order}[Address]

    # Variables for UI elements
    Set Local Variable    ${form}    xpath://html/body/div/div/div[1]/div/div[1]/form
    Set Local Variable    ${input_head}    head    #OR //*[@id="head"]
    Set Local Variable    ${input_body}    id-body-${body}
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    address    #OR //*[@id="address"]

    Wait Until Element Is Visible    ${form}

    # Input data to form
    Select From List By Value    ${input_head}    ${head}
    Click Element    ${input_body}
    Input Text    ${input_legs}    ${legs}
    Input Text    ${input_address}    ${address}

Preview the robot
    # Variables for UI elements
    Set Local Variable    ${button_preview}    preview
    Set Local Variable    ${robot_screen}    robot-preview-image

    # Preview robot
    Click Button    ${button_preview}

    Wait Until Element Is Visible    ${robot_screen}

Submit the order
    # Variables for UI elements
    Set Local Variable    ${button_order}    order
    Set Local Variable    ${receipt}    receipt

    #Do not generate screenshots if the test fails
    Mute Run On Failure    Page Should Contain Element

    # Submit form
    Click Button    ${button_order}
    Page Should Contain Element    ${receipt}

Store the order receipt as a PDF file
    [Arguments]    ${pdf_folder}

    # Variables for UI elements
    Set Local Variable    ${input_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${receipt}    receipt

    Wait Until Element Is Visible    ${receipt}

    # Get the whole receipt
    ${order_receipt_html}    Get Element Attribute    receipt    outerHTML

    # Get the order ID
    ${orderid}    Get Text    ${input_orderid}

    # Create path
    Set Local Variable    ${pdf}    ${pdf_folder}${/}${orderid}.pdf
    # Convert Html to Pdf
    Html To Pdf    ${order_receipt_html}    ${pdf}

    RETURN    ${pdf}    ${orderid}

Take a screenshot of the robot image
    [Arguments]    ${orderid}    ${png_folder}

    # Create path
    Set Local Variable    ${png}    ${png_folder}${/}${orderid}.png

    # Take screenshot
    Screenshot    robot-preview-image    ${png}

    RETURN    ${png}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${png}    ${pdf}

    Open Pdf    ${pdf}

    # THIS STEP IS FROM GitHub
    # https://github.com/joergschultzelutter/robocorp-certification-level-ii/blob/master/order-processing-robot/tasks.robot
    @{myfiles}    Create List    ${png}:x=0,y=0

    Add Files To PDF    ${myfiles}    ${pdf}    ${True}

    Close PDF    ${pdf}

Go to order another robot
    #Go to next order
    Click Button    order-another

Create a ZIP file of receipt PDF files
    [Arguments]    ${pdf_folder}    ${pdfs}

    # Archive to .zip
    Archive Folder With Zip    ${pdf_folder}    ${pdfs}

Logout and Close Browser
    # Close Browser
    Close Browser
